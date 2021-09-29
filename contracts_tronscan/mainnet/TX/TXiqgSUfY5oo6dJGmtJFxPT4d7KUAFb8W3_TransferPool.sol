//SourceUnit: multisend.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);

}


contract TransferPool is Ownable {
    using SafeMath for uint;

    event TokenTransfer(address beneficiary, uint amount);
    event amountTransfered(address indexed fromAddress,address contractAddress,address indexed toAddress, uint256 indexed amount);
    event TokenDeposited(address indexed beneficiary, uint amount);
    event TrxDeposited(address indexed beneficiary, uint amount);
    

    constructor() public {
        /* Empty Constructor */
    }
   
    
    // This Will drop cryptocurrency to various account
    function transferCrypto(uint256[] memory amounts, address payable[] memory receivers) payable public  onlyOwner returns (bool){
        uint total = 0;
        require(amounts.length == receivers.length);
        require(receivers.length <= 100); //maximum receievers can be 100
        for(uint j = 0; j < amounts.length; j++) {
            total = total.add(amounts[j]);
        }
        require(total <= msg.value);
            
        for(uint i = 0; i< receivers.length; i++){
            receivers[i].transfer(amounts[i]);
            emit amountTransfered(msg.sender,address(this) ,receivers[i],amounts[i]);
        }
        return true;
    }
    
    // This will drop Tokens to various accounts
    function dropTokens(address[] memory _recipients, uint256[] memory _amount, address _tokenAddr) public onlyOwner returns (bool) {
        uint total = 0;
        require(_recipients.length == _amount.length);
        require(_recipients.length <= 100); //maximum receievers can be 100
        for(uint j = 0; j < _amount.length; j++) {
            total = total.add(_amount[j]);
        }
        require(total <= Token(_tokenAddr).balanceOf(address(this)),"Token Balance of contract is less than the total Airdrop");
        

        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0));
            require(Token(_tokenAddr).transfer(_recipients[i], _amount[i]));
        }

        return true;
    }
    

    
    // This will drop Tokens to various accounts (First Approve tokens from Token Contract)
    function depositTokens(uint256  _amount, address _tokenAddr) public returns (bool) {
        require(_amount <= Token(_tokenAddr).balanceOf(msg.sender),"Token Balance of user is less");
        require(Token(_tokenAddr).transferFrom(msg.sender,address(this), _amount));
        emit TokenDeposited(msg.sender, _amount);
        return true;
    }

    // This Will Deposit cryptocurrency to Contract
    function depositCrypto() payable public returns (bool){
        uint256 amount = msg.value;
        address userAddress = msg.sender;
        emit TrxDeposited(userAddress, amount);

        return true;
    }

    function withdrawTokens(address beneficiary, address _tokenAddr) public onlyOwner {
        require(Token(_tokenAddr).transfer(beneficiary, Token(_tokenAddr).balanceOf(address(this))));
    }

    function withdrawCrypto(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }
    function tokenBalance(address _tokenAddr) public view returns (uint256){
        return Token(_tokenAddr).balanceOf(address(this));
    }
    function cryptoBalance() public view returns (uint256){
        return address(this).balance;
    }
    
}