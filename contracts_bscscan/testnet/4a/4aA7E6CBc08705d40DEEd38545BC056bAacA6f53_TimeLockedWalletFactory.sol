/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

/**
 *Submitted for verification at Etherscan.io on 2018-01-30
*/

pragma solidity ^0.4.18;


/**
 * @title ERC20
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint256 public totalSupply;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract TimeLockedWallet {

    address public creator;
    address public owner;
    uint public unlockDate;
    uint public createdAt;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function TimeLockedWallet(
        address _creator,
        address _owner,
        uint _unlockDate
    ) public {
        creator = _creator;
        owner = _owner;
        unlockDate = _unlockDate;
        createdAt = now;
    }

    // keep all the ether sent to this address
    function() payable public { 
        Received(msg.sender, msg.value);
    }

    // callable by owner only, after specified time
    function withdraw() onlyOwner public {
       require(now >= unlockDate);
       //now send all the balance
       msg.sender.transfer(this.balance);
       Withdrew(msg.sender, this.balance);
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract) onlyOwner public {
       require(now >= unlockDate);
       ERC20 token = ERC20(_tokenContract);
       //now send all the token balance
       uint tokenBalance = token.balanceOf(this);
       token.transfer(owner, tokenBalance);
       WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    }

    function info() public view returns(address, address, uint, uint, uint) {
        return (creator, owner, unlockDate, createdAt, this.balance);
    }

    event Received(address from, uint amount);
    event Withdrew(address to, uint amount);
    event WithdrewTokens(address tokenContract, address to, uint amount);
}

contract TimeLockedWalletFactory {
 
    mapping(address => address[]) wallets;

    function getWallets(address _user) 
        public
        view
        returns(address[])
    {
        return wallets[_user];
    }

    function newTimeLockedWallet(address _owner, uint _unlockDate)
        payable
        public
        returns(address wallet)
    {
        // Create new wallet.
        wallet = new TimeLockedWallet(msg.sender, _owner, _unlockDate);
        
        // Add wallet to sender's wallets.
        wallets[msg.sender].push(wallet);

        // If owner is the same as sender then add wallet to sender's wallets too.
        if(msg.sender != _owner){
            wallets[_owner].push(wallet);
        }

        // Send ether from this transaction to the created contract.
        wallet.transfer(msg.value);

        // Emit event.
        Created(wallet, msg.sender, _owner, now, _unlockDate, msg.value);
    }

    // Prevents accidental sending of ether to the factory
    function () public {
        revert();
    }

    event Created(address wallet, address from, address to, uint createdAt, uint unlockDate, uint amount);
}