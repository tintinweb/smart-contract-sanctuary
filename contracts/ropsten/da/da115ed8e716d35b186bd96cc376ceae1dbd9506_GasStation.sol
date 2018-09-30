pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/GasStation.sol

contract GasStation is Ownable {
	// track used fillup hashes
	mapping(bytes32=>bool) usedhashes;
	address public gasStationSigner;
	uint256 public maxGas;

	// constructor
	constructor (address _gasStationSigner,uint256 _maxGas) payable public {
		setParameters(_gasStationSigner,_maxGas);
	}

	// default function
	function() payable public {}

	// swap tokens for gas
	function purchaseGas(address _tokenAddress, address _client, uint _validUntil, uint _tokenAmount, uint _gasAmount, uint8 _v, bytes32 _r, bytes32 _s) public {
		bytes32 hash = sha256(abi.encodePacked(_tokenAddress, this, _tokenAmount, _gasAmount, _validUntil));
		require(
			(usedhashes[hash] != true)
			&& (msg.sender == gasStationSigner)
			&& (ecrecover(hash, _v, _r, _s) == _client)
			&& (block.number <= _validUntil) 
			&& (_gasAmount <= maxGas)
			&& (_tokenAmount > 0)
		);
		// invalidate this deal&#39;s hash
		usedhashes[hash] = true;
		// take tokens
		ERC20 token = ERC20(_tokenAddress);
		require(token.transferFrom(_client, owner, _tokenAmount));
		// send gas
		_client.transfer(_gasAmount);
	}

	function setParameters(address _gasStationSigner,uint256 _maxGas) onlyOwner public {
		gasStationSigner = _gasStationSigner;
		maxGas = _maxGas;
	}

	function withdrawETH() onlyOwner public {
		owner.transfer(address(this).balance);
	}
}