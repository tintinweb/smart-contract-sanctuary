/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity ^0.4.25;


/**
 * @title ERC20
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IRC20 {
  uint256 public totalSupply;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



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

contract TimeLockedWallet {

    address public beneficiary;
    address public owner;
    uint256 public unlockDate;
    uint256 public createdAt;

    modifier onlyOwner {
        require(msg.sender == owner, 'Not the OWNER');
        _;
    }

    constructor(
        address _beneficiary,
        uint256 _unlockDate
    ) public {
        beneficiary = _beneficiary;
        owner = msg.sender;
        unlockDate = _unlockDate;
        createdAt = now;
    }

    // keep all the ether sent to this address
    function() payable public {
        emit Received(msg.sender, msg.value);
    }

    // callable by owner only, after specified time
    function withdraw() onlyOwner public {
       require(now >= unlockDate);
       //now send all the balance
       msg.sender.transfer(address(this).balance);
       emit Withdrew(msg.sender, address(this).balance);
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract) onlyOwner public {
       require(now >= unlockDate, 'Date NotStarted');
       IRC20 token = IRC20(_tokenContract);
       //now send all the token balance
       uint256 tokenBalance = token.balanceOf(this);
       
       token.transfer(beneficiary, tokenBalance);
       emit WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    }

    function info() public view returns(address, address, uint256, uint256, uint256) {
        return (beneficiary, owner, unlockDate, createdAt, address(this).balance);
    }

    function getBeneficiary() public view returns (address){
        return beneficiary;
    }
    
    function getOwner() public view returns (address){
        return owner;
    }

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}

contract TimeLockedWalletFactory {

    mapping(address => address[]) wallets;
    State public state;
    address owner = 0x2E6F7c485914FFC25356DEC9d5BAC6aC3cAE80c3;
    address private kphi = 0xF47b96c3917EEa571CA1ECDA4b5D9F99EF6d9E85;
    
    enum State {
        NotStarted,
        Ongoing,
        Finished
    }

    
    function getWallets(address _user)
    public
    view
    returns (address[])
    {
        return wallets[_user];
    }

    function newTimeLockedWallet(address _beneficiary, uint256 _unlockDate)
    payable
    public
    returns (address wallet)
    {
        state = State.NotStarted;
        // Create new wallet.
        wallet = new TimeLockedWallet(_beneficiary , _unlockDate);

        // Add wallet to sender's wallets.
        wallets[msg.sender].push(wallet);

        // If owner is the same as sender then add wallet to sender's wallets too.
        if (msg.sender != _beneficiary) {
            wallets[_beneficiary].push(wallet);
        }

        state = State.Ongoing;

        // Emit event.
        emit Created(wallet, msg.sender, _beneficiary, now, _unlockDate, msg.value);
    }
    
    function claimTokens (address _contractAddress)  public returns (string){
        TimeLockedWallet timeLockedWallet = TimeLockedWallet(_contractAddress);
        require(msg.sender == timeLockedWallet.getBeneficiary(), 'Sender not equals to beneficiary');
        timeLockedWallet.withdrawTokens(kphi);
        state = State.Finished;
        return "Everything fine";
    }

    function getInfo(address _contractAddress) public view returns(address, address, uint256, uint256, uint256){
        TimeLockedWallet tlw = TimeLockedWallet(_contractAddress);
        return tlw.info();
    }

    // Prevents accidental sending of ether to the factory
    function() public {
        revert();
    }
    
    function destroySmartContract(address _to) public {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(_to);
    }

    event Created(address wallet, address from, address to, uint256 createdAt, uint256 unlockDate, uint256 amount);
}