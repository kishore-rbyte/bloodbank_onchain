// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract BloodDonationSystem {
    // Enums
    enum BloodType { APositive, ANegative, BPositive, BNegative, ABPositive, ABNegative, OPositive, ONegative }

    // Structs
    struct Donor {
        string name;
        address donorAddress;
        BloodType bloodType;
        uint256 lastDonationTime;
        mapping(address => uint256) donationHistory; // Mapping of blood bank addresses to donation timestamps
    }

    struct BloodBank {
        string name;
        address owner;
        mapping(BloodType => uint256) bloodStock; // Mapping of blood types to their stock counts
        mapping(address => Donor) donors; // Mapping of donor addresses to their details
    }

    // Arrays
    address[] public bloodBankAddresses; // Array to store registered blood bank addresses

    // Mappings
    mapping(address => BloodBank) public bloodBanks;
    mapping(address => bool) public isDonor;
    uint256 public minDonationInterval = 90 days; // Minimum interval between donations

    // Events
    event BloodBankRegistered(address indexed bankAddress, string name);
    event DonorRegistered(address indexed donorAddress, string name);
    event BloodDonated(address indexed donorAddress, address indexed bankAddress, BloodType bloodType, uint256 amount);

    // Modifiers
    modifier onlyBloodBank() {
        require(isBloodBankRegistered(msg.sender), "Only registered blood banks can perform this action");
        _;
    }

    // Register a new blood bank
    function registerBloodBank(string memory _name) public {
        require(!isBloodBankRegistered(msg.sender), "Blood bank already registered");
        
        BloodBank storage newBloodBank = bloodBanks[msg.sender];
        newBloodBank.name = _name;
        newBloodBank.owner = msg.sender;

        bloodBankAddresses.push(msg.sender); // Add the blood bank address to the array

        emit BloodBankRegistered(msg.sender, _name);
    }

    // Register a new donor
    function registerDonor(string memory _name, BloodType _bloodType) public {
        require(!isDonor[msg.sender], "Already registered as a donor");
        isDonor[msg.sender] = true;
        
        Donor storage donor = bloodBanks[msg.sender].donors[msg.sender];
        donor.name = _name;
        donor.donorAddress = msg.sender;
        donor.bloodType = _bloodType;
        donor.lastDonationTime = 0;

        emit DonorRegistered(msg.sender, _name);
    }

    // Donate blood to a blood bank
    function donateBlood(address _bloodBankAddress, uint256 _amount) public {
        require(isDonor[msg.sender], "Not registered as a donor");
        require(isBloodBankRegistered(_bloodBankAddress), "Invalid blood bank address");
        Donor storage donor = bloodBanks[_bloodBankAddress].donors[msg.sender];
        require(block.timestamp >= donor.lastDonationTime + minDonationInterval, "Minimum donation interval not met");
        donor.lastDonationTime = block.timestamp;
        donor.donationHistory[_bloodBankAddress] = block.timestamp;
        bloodBanks[_bloodBankAddress].bloodStock[donor.bloodType] += _amount;
        emit BloodDonated(msg.sender, _bloodBankAddress, donor.bloodType, _amount);
    }

    // Get all registered blood bank addresses
    function getBloodBankAddresses() public view returns (address[] memory) {
        return bloodBankAddresses;
    }

    // Get a donor's donation history with a specific blood bank
    function getDonationHistory(address _bloodBankAddress) public view returns (uint256[] memory) {
        require(isDonor[msg.sender], "Not registered as a donor");
        require(isBloodBankRegistered(_bloodBankAddress), "Invalid blood bank address");
        Donor storage donor = bloodBanks[_bloodBankAddress].donors[msg.sender];
        uint256[] memory history = new uint256[](1);
        history[0] = donor.donationHistory[_bloodBankAddress];
        return history;
    }

    // Get the blood stock of a blood bank
    function getBloodStock(address _bloodBankAddress) public view onlyBloodBank returns (uint256[8] memory) {
        BloodBank storage bank = bloodBanks[_bloodBankAddress];
        uint256[8] memory stock;
        stock[0] = bank.bloodStock[BloodType.APositive];
        stock[1] = bank.bloodStock[BloodType.ANegative];
        stock[2] = bank.bloodStock[BloodType.BPositive];
        stock[3] = bank.bloodStock[BloodType.BNegative];
        stock[4] = bank.bloodStock[BloodType.ABPositive];
        stock[5] = bank.bloodStock[BloodType.ABNegative];
        stock[6] = bank.bloodStock[BloodType.OPositive];
        stock[7] = bank.bloodStock[BloodType.ONegative];
        return stock;
    }

    // Check if an address is a registered blood bank
    function isBloodBankRegistered(address _address) public view returns (bool) {
        return bloodBanks[_address].owner != address(0);
    }
}
