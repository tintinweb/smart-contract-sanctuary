pragma solidity ^0.4.21;

// File: contracts/Interfaces/MasterDepositInterface.sol

/**
 * @dev Interface of MasterDeposit that should be used in child contracts 
 * @dev this ensures that no duplication of code and implicit gasprice will be used for the dynamic creation of child contract
 */
contract MasterDepositInterface {
    address public coldWallet1;
    address public coldWallet2;
    uint public percentage;
    function fireDepositToChildEvent(uint _amount) public;
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/ChildDeposit.sol

/**
* @dev Should be dinamically created from master contract 
* @dev multiple payers can contribute here 
*/
contract ChildDeposit {
    
    /**
    * @dev prevents over and under flows
    */
    using SafeMath for uint;
    
    /**
    * @dev import only the interface for low gas cost
    */
    // MasterDepositInterface public master;
    address masterAddress;

    function ChildDeposit() public {
        masterAddress = msg.sender;
        // master = MasterDepositInterface(msg.sender);
    }

    /**
    * @dev any ETH income will fire a master deposit contract event
    * @dev the redirect of ETH will be split in the two wallets provided by the master with respect to the share percentage set for wallet 1 
    */
    function() public payable {

        MasterDepositInterface master = MasterDepositInterface(masterAddress);
        // fire transfer event
        master.fireDepositToChildEvent(msg.value);

        // trasnfer of ETH
        // with respect to the percentage set
        uint coldWallet1Share = msg.value.mul(master.percentage()).div(100);
        
        // actual transfer
        master.coldWallet1().transfer(coldWallet1Share);
        master.coldWallet2().transfer(msg.value.sub(coldWallet1Share));
    }

    /**
    * @dev function that can only be called by the creator of this contract
    * @dev the actual condition of transfer is in the logic of the master contract
    * @param _value ERC20 amount 
    * @param _tokenAddress ERC20 contract address 
    * @param _destination should be onbe of the 2 coldwallets
    */
    function withdraw(address _tokenAddress, uint _value, address _destination) public onlyMaster {
        ERC20(_tokenAddress).transfer(_destination, _value);
    }

    modifier onlyMaster() {
        require(msg.sender == address(masterAddress));
        _;
    }
    
}

// File: zeppelin-solidity/contracts/ReentrancyGuard.sol

/**
 * @title Helps contracts guard agains reentrancy attacks.
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="44362129272b0476">[email&#160;protected]</span>&#207;€.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/MasterDeposit.sol

/**
* @dev master contract that creates ChildDeposits. Responsible for controlling and setup of deposit chain.  
* @dev all functions that should be called from child deposits are specified in the MasterDepositInterface 
*/
contract MasterDeposit is MasterDepositInterface, Claimable, ReentrancyGuard {
    
    /**
    * @dev prevents over and under flows
    */
    using SafeMath for uint;

    /**
    * @dev mapping of all created child deposits
    */
    mapping (address => bool) public childDeposits;

    /**
    * @dev responsible for creating deposits (in this way the owner isn&#39;t exposed to a api/server security breach)
    * @dev by loosing the depositCreator key an attacker can only create deposits that will not be a real threat and another depositCreator can be allocated
    */
    address public depositCreator;

    /**
    * @dev Fired at create time
    * @param _depositAddress blockchain address of the newly created deposit contract
    */
    event CreatedDepositEvent (
    address indexed _depositAddress
    );
    
    /**
    * @dev Fired at transfer time
    * @dev Event that signals the transfer of an ETH amount 
    * @param _depositAddress blockchain address of the deposit contract that received ETH
    * @param _amount of ETH
    */
    event DepositToChildEvent(
    address indexed _depositAddress, 
    uint _amount
    );


    /**
    * @param _wallet1 redirect of tokens (ERC20) or ETH
    * @param _wallet2 redirect of tokens (ERC20) or eth
    * @param _percentage _wallet1 split percentage 
    */
    function MasterDeposit(address _wallet1, address _wallet2, uint _percentage) onlyValidPercentage(_percentage) public {
        require(_wallet1 != address(0));
        require(_wallet2 != address(0));
        percentage = _percentage;
        coldWallet1 = _wallet1;
        coldWallet2 = _wallet2;
    }

    /**
    * @dev creates a number of instances of ChildDeposit contracts
    * @param _count creates a specified number of deposit contracts
    */
    function createChildDeposits(uint _count) public onlyDepositCreatorOrMaster {
        for (uint i = 0; i < _count; i++) {
            ChildDeposit childDeposit = new ChildDeposit();
            childDeposits[address(childDeposit)] = true;
            emit CreatedDepositEvent(address(childDeposit));    
        }
    }

    /**
    * @dev setter for the address that is responsible for creating deposits 
    */
    function setDepositCreator(address _depositCreator) public onlyOwner {
        require(_depositCreator != address(0));
        depositCreator = _depositCreator;
    }

    /**
    * @dev Setter for the income percentage in the first coldwallet (not setting this the second wallet will receive all income)
    */
    function setColdWallet1SplitPercentage(uint _percentage) public onlyOwner onlyValidPercentage(_percentage) {
        percentage = _percentage;
    }

    /**
    * @dev function created to emit the ETH transfer event from the child contract only
    * @param _amount ETH amount 
    */
    function fireDepositToChildEvent(uint _amount) public onlyChildContract {
        emit DepositToChildEvent(msg.sender, _amount);
    }

    /**
    * @dev changes the coldwallet1 address
    */
    function setColdWallet1(address _coldWallet1) public onlyOwner {
        require(_coldWallet1 != address(0));
        coldWallet1 = _coldWallet1;
    }

    /**
    * @dev changes the coldwallet2 address
    */
    function setColdWallet2(address _coldWallet2) public onlyOwner {
        require(_coldWallet2 != address(0));
        coldWallet2 = _coldWallet2;
    }

    /**
    * @dev function that can be called only by owner due to security reasons and will withdraw the amount of ERC20 tokens
    * @dev from the deposit contract list to the cold wallets 
    * @dev transfers only the ERC20 tokens, ETH should be transferred automatically
    * @param _deposits batch list with all deposit contracts that might hold ERC20 tokens
    * @param _tokenContractAddress specifies what token to be transfered form each deposit from the batch to the cold wallets
    */
    function transferTokens(address[] _deposits, address _tokenContractAddress) public onlyOwner nonReentrant {
        for (uint i = 0; i < _deposits.length; i++) {
            address deposit = _deposits[i];
            uint erc20Balance = ERC20(_tokenContractAddress).balanceOf(deposit);

            // if no balance found just skip
            if (erc20Balance == 0) {
                continue;
            }
            
            // trasnfer of erc20 tokens
            // with respect to the percentage set
            uint coldWallet1Share = erc20Balance.mul(percentage).div(100);
            uint coldWallet2Share = erc20Balance.sub(coldWallet1Share); 
            ChildDeposit(deposit).withdraw(_tokenContractAddress,coldWallet1Share, coldWallet1);
            ChildDeposit(deposit).withdraw(_tokenContractAddress,coldWallet2Share, coldWallet2);
        }
    }

    modifier onlyChildContract() {
        require(childDeposits[msg.sender]);
        _;
    }

    modifier onlyDepositCreatorOrMaster() {
        require(msg.sender == owner || msg.sender == depositCreator);
        _;
    }

    modifier onlyValidPercentage(uint _percentage) {
        require(_percentage >=0 && _percentage <= 100);
        _;
    }

}