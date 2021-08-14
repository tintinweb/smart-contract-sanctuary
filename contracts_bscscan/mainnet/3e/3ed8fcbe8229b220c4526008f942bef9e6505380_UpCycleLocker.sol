/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

/**
 * RISKDROP - modified for the UpCycle Team
 * 
 * More Power to the crowd, the token is about distributing risk.
 * hedging your gamma from the unexepcted "Delta"
 * 
 * OG Maker https://t.me/defispeculate
 * UpCycle https://t.me/upcyclefinance
 * https://upcycle.finance
 * 
 * 
 */

pragma solidity 0.4.24;


/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}

// File: contracts/UpgradeabilityOwnerStorage.sol

// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender


/**
 * @title UpgradeabilityOwnerStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract UpgradeabilityOwnerStorage {
  // Owner of the contract
    address private _upgradeabilityOwner;

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
    * @dev Sets the address of the owner
    */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

}

// File: contracts/UpgradeabilityStorage.sol

// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender


/**
 * @title UpgradeabilityStorage
 * @dev This contract holds all the necessary state variables to support the upgrade functionality
 */
contract UpgradeabilityStorage {
  // Version name of the current implementation
    string internal _version;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the version name of the current implementation
    * @return string representing the name of the current version
    */
    function version() public view returns (string) {
        return _version;
    }

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

// File: contracts/OwnedUpgradeabilityStorage.sol

// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender





/**
 * @title OwnedUpgradeabilityStorage
 * @dev This is the storage necessary to perform upgradeable contracts.
 * This means, required state variables for upgradeability purpose and eternal storage per se.
 */
contract OwnedUpgradeabilityStorage is UpgradeabilityOwnerStorage, UpgradeabilityStorage, EternalStorage {}

// File: contracts/SafeMath.sol

// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender


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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: contracts/multisender/Ownable.sol

// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender



/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return addressStorage[keccak256("owner")];
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256("owner")] = newOwner;
    }
}

// File: contracts/multisender/Claimable.sol

// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender




/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is EternalStorage, Ownable {
    function pendingOwner() public view returns (address) {
        return addressStorage[keccak256("pendingOwner")];
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner());
        _;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        addressStorage[keccak256("pendingOwner")] = newOwner;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner(), pendingOwner());
        addressStorage[keccak256("owner")] = addressStorage[keccak256("pendingOwner")];
        addressStorage[keccak256("pendingOwner")] = address(0);
    }
}

// File: contracts/multisender/UpgradebleStormSender.sol

// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender




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


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract UpCycleLocker is OwnedUpgradeabilityStorage, Claimable {
    using SafeMath for uint256;

    event Multisended(uint256 total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint256 balance);

    modifier hasFee() {
        if (currentFee(msg.sender) > 0) {
            require(msg.value >= currentFee(msg.sender));
        }
        _;
    }

    function() public payable {}

    function initialize(address _owner) public {
        require(!initialized());
        setOwner(_owner);
        setArrayLimit(200);
        setDiscountStep(0.00005 ether);
        setFee(0.00001 ether);
        boolStorage[keccak256("rs_multisender_initialized")] = true;
    }

    function initialized() public view returns (bool) {
        return boolStorage[keccak256("rs_multisender_initialized")];
    }
 
    function txCount(address customer) public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("txCount", customer))];
    }

    function arrayLimit() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("arrayLimit"))];
    }

    function setArrayLimit(uint256 _newLimit) public onlyOwner {
        require(_newLimit != 0);
        uintStorage[keccak256("arrayLimit")] = _newLimit;
    }

    function discountStep() public view returns(uint256) {
        return uintStorage[keccak256("discountStep")];
    }

    function setDiscountStep(uint256 _newStep) public onlyOwner {
        require(_newStep != 0);
        uintStorage[keccak256("discountStep")] = _newStep;
    }

    function fee() public view returns(uint256) {
        return uintStorage[keccak256("fee")];
    }

    function currentFee(address _customer) public view returns(uint256) {
        if (fee() > discountRate(msg.sender)) {
            return fee().sub(discountRate(_customer));
        } else {
            return 0;
        }
    }

    function setFee(uint256 _newStep) public onlyOwner {
        require(_newStep != 0);
        uintStorage[keccak256("fee")] = _newStep;
    }

    function discountRate(address _customer) public view returns(uint256) {
        uint256 count = txCount(_customer);
        return count.mul(discountStep());
    }

    function multisendToken(address token, address[] _contributors, uint256[] _balances) public hasFee payable {
        if (token == 0x000000000000000000000000000000000000bEEF){
            multisendEther(_contributors, _balances);
        } else {
            uint256 total = 0;
            require(_contributors.length <= arrayLimit());
            ERC20 erc20token = ERC20(token);
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
                erc20token.transferFrom(msg.sender, _contributors[i], _balances[i]);
                total += _balances[i];
            }
            setTxCount(msg.sender, txCount(msg.sender).add(1));
            emit Multisended(total, token);
        }
    }

    function multisendEther(address[] _contributors, uint256[] _balances) public payable {
        uint256 total = msg.value;
        uint256 userfee = currentFee(msg.sender);
        require(total >= userfee);
        require(_contributors.length <= arrayLimit());
        total = total.sub(userfee);
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        setTxCount(msg.sender, txCount(msg.sender).add(1));
        emit Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner().transfer(address(this).balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(this);
        erc20token.transfer(owner(), balance);
        emit ClaimedTokens(_token, owner(), balance);
    }
    
    function setTxCount(address customer, uint256 _txCount) private {
        uintStorage[keccak256(abi.encodePacked("txCount", customer))] = _txCount;
    }

}