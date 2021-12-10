/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity ^0.8.1;

interface PriceFeed{
    function setPrice(uint _price) external;
    function latestAnswer() external view returns (uint);
}

pragma solidity ^0.8.1;

interface ERC20{
    function mint(address to, uint amount) external;
    function decimals() external view returns(uint);
}

pragma solidity ^0.8.1;

contract TesterHub {

    mapping(string => address) public tokens;
    mapping(address => uint) public mintBalance;
    mapping(string => address) public priceFeeds;

    uint public globalLimit;
    uint public globalMintAmount;

    address deployer;

    constructor(string[] memory _tokenNames,address[] memory _tokenAddresses,address[] memory _priceFeeds){
        require(_tokenNames.length == _tokenAddresses.length);
        deployer = msg.sender;
        for (uint8 i = 0; i < _tokenNames.length; i++) {
            tokens[_tokenNames[i]] = _tokenAddresses[i];
            priceFeeds[_tokenNames[i]] = _priceFeeds[i];
        }
    }

    function updateGlobalLimit(uint newLimit) external {
        require(deployer == msg.sender);
        globalLimit = newLimit;
    }

    function mintToken(string memory _tokenName, address _receiverAddress, uint _amount) external {
        require(_amount>0);
        require(_receiverAddress != address(0));
        require(tokens[_tokenName] != address(0));
        uint mintValue = PriceFeed(priceFeeds[_tokenName]).latestAnswer() * _amount / (10**ERC20(tokens[_tokenName]).decimals());
        require((mintBalance[_receiverAddress] + mintValue) <= 100000000000000, "Mint limit of one million reached");    
        require(globalMintAmount + mintValue <= globalLimit);

        mintBalance[_receiverAddress] += mintValue;
        globalMintAmount += mintValue;
        ERC20(tokens[_tokenName]).mint(_receiverAddress, _amount);
    }
}