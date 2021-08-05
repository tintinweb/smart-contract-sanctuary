/**
 *Submitted for verification at Etherscan.io on 2020-01-06
*/

/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.10;

/*
 * MintHelper and MultiSend for BSOV Mining Pool
 * BitcoinSoV (BSOV) Mineable & Deflationary
 *
 * https://www.btcsov.com
 * https://bsov-pool.hashtables.net
 *
 * Based off https://github.com/0xbitcoin/mint-helper
 */


contract Ownable {
    address private _owner;
    address private _payoutWallet;  // Added to prevent payouts interfering with minting requests. 

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        _payoutWallet = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    function payoutWallet() public view returns (address) {
        return _payoutWallet;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner, minter, or payer.");
        _;
    }
    
    modifier onlyPayoutWallet() {
        require(msg.sender == _owner || msg.sender == _payoutWallet, "Ownable: caller is not the owner or payer.");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function setPayoutWallet(address newAddress) public onlyOwner {
        _payoutWallet = newAddress;
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ERC918Interface {
  function totalSupply() public view returns (uint);
  function getMiningDifficulty() public view returns (uint);
  function getMiningTarget() public view returns (uint);
  function getMiningReward() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
}

/*
The mintingWallet will proxy mint requests to be credited to the contract address.
The payoutWallet will call the multisend method to send out payments.
*/

contract PoolHelper is Ownable {
    string public name;
    address public mintableToken;
    mapping(bytes32 => bool) successfulPayments;

    event Payment(bytes32 _paymentId);
    
    constructor(address mToken, string memory mName)
    public
    {
      mintableToken = mToken;
      name = mName;
    }

    function setMintableToken(address mToken)
    public onlyOwner
    returns (bool)
    {
      mintableToken = mToken;
      return true;
    }

    function paymentSuccessful(bytes32 paymentId) public view returns (bool){
        return (successfulPayments[paymentId] == true);
    }
    
    function proxyMint(uint256 nonce, bytes32 challenge_digest )
    public
    returns (bool)
    {
      require(ERC918Interface(mintableToken).mint(nonce, challenge_digest), "Could not mint token");
      return true;
    }

    //withdraw any eth inside
    function withdraw()
    public onlyOwner
    {
        msg.sender.transfer(address(this).balance);
    }
    
    //send tokens out
    function send(address _tokenAddr, bytes32 paymentId, address dest, uint value)
    public onlyPayoutWallet
    returns (bool)
    {
        require(successfulPayments[paymentId] != true, "Payment ID already exists and was successful");
        successfulPayments[paymentId] = true;
        emit Payment(paymentId);
        return ERC20Interface(_tokenAddr).transfer(dest, value);
    }

    //batch send tokens
    function multisend(address _tokenAddr, bytes32 paymentId, address[] memory dests, uint256[] memory values)
    public onlyPayoutWallet
    returns (uint256)
    {
        require(dests.length > 0, "Must have more than 1 destination address");
        require(values.length >= dests.length, "Address to Value array size mismatch");
        require(successfulPayments[paymentId] != true, "Payment ID already exists and was successful");

        uint256 i = 0;
        while (i < dests.length) {
           require(ERC20Interface(_tokenAddr).transfer(dests[i], values[i]));
           i += 1;
        }

        successfulPayments[paymentId] = true;
        emit Payment(paymentId);
        return (i);
    }
}