pragma solidity ^0.4.24;
contract TokenFace {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract WalletPlus {
    address public owner;
    address public instantTokenAddress;
    mapping(address => uint256) tokenRates;
    event DataLength(uint256 _dataLength);
    event TransferFailed(address indexed _tokenAddress, address indexed _from, address indexed _to, uint256 _value);
    constructor() public {
        owner = msg.sender;
        instantTokenAddress = address(0);
        tokenRates[address(0)] = 0;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function changeAdmin(address adminAddress) public admin returns(bool success) {
        require(adminAddress != address(0) && address(this) != adminAddress);
        owner = adminAddress;
        return true;
    }
    //update token rate
    //set rate to 1
    function updateRate(address tokenAddress, uint256 rate) public admin returns(bool success) {
        require(tokenAddress != address(0) && rate >= 2);
        tokenRates[tokenAddress] = rate;
        return true;
    }
    //update instant sell token address
    //set to 0x0000000000000000000000000000000000000000
    //if you want to disable instant sell
    //but everyone can buy your token by calling function buy(@param token)
    //if token rate > 1;
    function updateInstantToken(address tokenAddress) public admin returns(bool success) {
        require(tokenRates[tokenAddress] > 1);
        instantTokenAddress = tokenAddress;
        return true;
    }
    //check token rate
    function getTokenRate(address tokenAddress) public view returns(uint256) {
        return tokenRates[tokenAddress];
    }
    //everyone can buy your token by calling this function
    function buy(address tokenAddress) public payable returns(bool success) {
        require(tokenRates[tokenAddress] > 1 && msg.value > 0);
        uint256 amount = msg.value * tokenRates[tokenAddress];
        uint256 readyStock = TokenFace(tokenAddress).balanceOf(address(this));
        uint256 exToken = readyStock - amount;
        uint256 exEther = 0;
        uint256 value = amount;
        if (amount > readyStock) {
            value = readyStock;
            exToken = amount - readyStock;
            exEther = exToken / tokenRates[tokenAddress];
        }
        TokenFace(tokenAddress).transfer(msg.sender, value);
        if (exEther - 1 > 0) {
            msg.sender.transfer(exEther);
        }
        return true;
    }
    //fallback function
    function() public payable {
        emit DataLength(msg.data.length);
    }
    //Withdraw ether and token
    function withdraw(address tokenAddress) public admin returns(bool success) {
        uint256 tokenBalance = address(this).balance;
        if (tokenAddress == address(0)) {
            owner.transfer(tokenBalance);
        } else {
            tokenBalance = TokenFace(tokenAddress).balanceOf(address(this));
            TokenFace(tokenAddress).transfer(owner, tokenBalance);
        }
        return true;
    }
    //ether sender controlled by admin
    function sendEther(address to, uint256 value) public admin payable returns(bool success) {
        require(to != address(0) && value >= 1 && value <= address(this).balance);
        to.transfer(value);
        return true;
    }
    //token sender controlled by admin
    function sendToken(address tokenAddress, address to, uint256 value) public admin returns(bool success) {
        require(tokenAddress != address(0) && to != address(0) && value >= 1 && value < TokenFace(tokenAddress).balanceOf(msg.sender));
        if(!TokenFace(tokenAddress).transfer(to, value)) {
            emit TransferFailed(tokenAddress, address(this), to, value);
        }
        return true;
    }
    //usable for token airdrop and giveaway
    function bulkTokenSender(address[] tokenAddress, address[] dests, uint256[] values) public returns(uint i) {
        require(tokenAddress.length == dests.length && dests.length == values.length);
        for (i = 0; i < tokenAddress.length; i++) {
            if (tokenAddress[i] != address(0) && address(0) != dests[i]) {
                if (!TokenFace(tokenAddress[i]).transferFrom(msg.sender, dests[i], values[i])) {
                    emit TransferFailed(tokenAddress[i], msg.sender, dests[i], values[i]);
                }
            } else {
                emit TransferFailed(tokenAddress[i], msg.sender, dests[i], values[i]);
            }
        }
        return i;
    }
    //ether multisender controlled by admin
    function bulkEtherSender(address[] dests, uint256[] values) public admin payable returns(uint j) {
        require(dests.length == values.length);
        for (j = 0; j < dests.length; j++) {
            if (address(0) != dests[j]) {
                dests[j].transfer(values[j]);
            } else {
                emit TransferFailed(address(0), address(this), dests[j], values[j]);
            }
        }
        return j;
    }
    //Destroy this contract when bug found
    function kill(address[] tokenAddress) public admin returns(bool success) {
        require(tokenAddress.length > 0);
        for (uint k = 0; k < tokenAddress.length; k++) {
            require(withdraw(tokenAddress[k]));
        }
        if (k == tokenAddress.length - 1) {
            selfdestruct(owner);
            return true;
        } else {
            revert();
        }
    }
}