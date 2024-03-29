// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;



import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EcoCoin {
    constructor()  {}

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    string public name = "EcoCoin";
    string public symbol = "ECO";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    function setTotalSupply(uint256 newTotalSupply) external  {
        totalSupply = newTotalSupply;
    }

    function balancesLength() external view returns (uint256) {
    uint256 length = 0;
    for (uint i = 0; i < totalSupply; i++) {
        address account = address(uint160(i));
        if (balances[account] > 0) {
            length++;
        }
    }
    return length;
}


    function setBalance(address account, uint256 amount) external  {
        balances[account] = amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) { /* ... */ }
    function approve(address spender, uint256 amount) external returns (bool) { /* ... */ }
    function transferFrom(address from, address to, uint256 amount) external returns (bool) { /* ... */ }
}


contract EcoCoinController  {
    EcoCoin public ecoCoin;
    AggregatorV3Interface public ethPriceFeed;
    uint256 public lastRebaseTimestamp;

    constructor(address _ecoCoin, address _ethPriceFeed)  {
        ecoCoin = EcoCoin(_ecoCoin);
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        ecoCoin.setTotalSupply(100000 * 10**ecoCoin.decimals()); // Initial supply of 1 lakh tokens
        lastRebaseTimestamp = block.timestamp;
    }


    

    event Rebase(uint256 prevSupply, uint256 newSupply);

function rebase() external  {
    uint256 prevSupply = ecoCoin.totalSupply();
    (, int256 latestPrice, , , ) = ethPriceFeed.latestRoundData();
    uint256 currentEthPrice = uint256(latestPrice);
    uint256 targetPrice = 1 * 10**18; // 1 ECO = 1 USD
    uint256 newSupply = (prevSupply * targetPrice * 10**ecoCoin.decimals()) / currentEthPrice;

    ecoCoin.setTotalSupply(newSupply);
    lastRebaseTimestamp = block.timestamp;

    uint256 balancesLength = ecoCoin.balancesLength();
    for (uint256 i = 0; i < balancesLength; i++) {
       address account = address(uint160(uint256(i)));
        uint256 balance = ecoCoin.balances(account);
        ecoCoin.setBalance(account, (balance * newSupply) / prevSupply);
    }

    emit Rebase(prevSupply, newSupply);
}
}
