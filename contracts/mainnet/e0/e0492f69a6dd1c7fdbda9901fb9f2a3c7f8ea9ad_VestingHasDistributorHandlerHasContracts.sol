pragma solidity ^0.4.24;

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

/**
 * @title ContractOwner
 * @dev The ContractOwner contract serves the role of interactng with the functions of Ownable contracts,
 * this simplifies the implementation of "user permissions".
 */
contract HasContracts is Ownable {

  /**
   * @dev Relinquish control of the owned _contract.
   */
  function renounceOwnedOwnership(address _contract) public onlyOwner {
    Ownable(_contract).renounceOwnership();
  }

  /**
   * @dev Transfer control of the owned _contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnedOwnership(address _contract, address _newOwner) public onlyOwner {
    Ownable(_contract).transferOwnership(_newOwner);
  }
}

contract IOwnable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function renounceOwnership() public;
  function transferOwnership(address _newOwner) public;
}

contract ITokenDistributor is IOwnable {

    address public targetToken;
    address[] public stakeHolders;
    uint256 public maxStakeHolders;
    event InsufficientTokenBalance( address indexed _token, uint256 _time );
    event TokensDistributed( address indexed _token, uint256 _total, uint256 _time );

    function isDistributionDue (address _token) public view returns (bool);
    function isDistributionDue () public view returns (bool);
    function countStakeHolders () public view returns (uint256);
    function getTokenBalance(address _token) public view returns (uint256);
    function getPortion (uint256 _total) public view returns (uint256);
    function setTargetToken (address _targetToken) public returns (bool);
    function distribute (address _token) public returns (bool);
    function distribute () public returns (bool);
}

/**
* A secondary contract which can interact directly with tokenDistributor
* and can ultimately be made Owner to acheieve full `Code is Law` state
*/
contract HasDistributorHandler is Ownable {
    /**
    *   Allows distributing of tokens from tokenDistributor contracts
    *   supports only 2 versions at present
    *   Version1 : distribute()
    *   version2 : distribute(address token) ( fallback() ) : for backward compatibility
    *
    *   version type has to be passed in to complete the release, default is version1.
    *  0 => version1
    *  1 => version2
    *
    */

    enum distributorContractVersion { v1, v2 }

    address public tokenDistributor;
    distributorContractVersion public distributorVersion;

    constructor (distributorContractVersion _distributorVersion, address _tokenDistributor) public Ownable() {
        setTokenDistributor(_distributorVersion, _tokenDistributor);
    }

    function setTokenDistributor (distributorContractVersion _distributorVersion, address _tokenDistributor) public onlyOwner returns (bool) {
      require(tokenDistributor == 0x0, &#39;Token Distributor already set&#39;);
      distributorVersion = _distributorVersion;
      tokenDistributor = _tokenDistributor;
      return true;
    }

    function distribute () public returns (bool) {
        require(tokenDistributor != 0x0, &#39;Token Distributor not set&#39;);

        if (distributorVersion == distributorContractVersion.v2) {
          /* TODO Check functionaliy and optimize  */
            return tokenDistributor.call(0x0);
        } else {
          return ITokenDistributor(tokenDistributor).distribute();
        }
        return false;
    }

    function () public {
      distribute();
    }
}

pragma solidity^0.4.24;

contract IVestingContract {
  function release() public;
  function release(address token) public;
}

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

contract TokenHandler is Ownable {

    address public targetToken;

    constructor ( address _targetToken) public Ownable() {
        setTargetToken(_targetToken);
    }

    function getTokenBalance(address _token) public view returns (uint256) {
        ERC20Basic token = ERC20Basic(_token);
        return token.balanceOf(address(this));
    }

    function setTargetToken (address _targetToken) public onlyOwner returns (bool) {
      require(targetToken == 0x0, &#39;Target token already set&#39;);
      targetToken = _targetToken;
      return true;
    }

    function _transfer (address _token, address _recipient, uint256 _value) internal {
        ERC20Basic token = ERC20Basic(_token);
        token.transfer(_recipient, _value);
    }
}

/*
Supports default zeppelin vesting contract
https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/TokenVesting.sol
*/





contract VestingHandler is TokenHandler {

    /**
    *   Allows releasing of tokens from vesting contracts
    *   supports only 2 versions at present
    *   Version1 : release()
    *   version2 : release(address token)
    *
    *   version type has to be passed in to complete the release, default is version1.
    *  0 => version1
    *  1 => version2
    */

    enum vestingContractVersion { v1, v2 }

    address public vestingContract;
    vestingContractVersion public targetVersion;

    constructor ( vestingContractVersion _targetVersion, address _vestingContract, address _targetToken) public
    TokenHandler(_targetToken){
        setVestingContract(_targetVersion, _vestingContract);
    }

    function setVestingContract (vestingContractVersion _version, address _vestingContract) public onlyOwner returns (bool) {
        require(vestingContract == 0x0, &#39;Vesting Contract already set&#39;);
        vestingContract = _vestingContract;
        targetVersion = _version;
        return true;
    }

    function _releaseVesting (vestingContractVersion _version, address _vestingContract, address _targetToken) internal returns (bool) {
        require(_targetToken != 0x0, &#39;Target token not set&#39;);
        if (_version == vestingContractVersion.v1) {
            return _releaseVesting (_version, _vestingContract);
        } else if (_version == vestingContractVersion.v2){
            IVestingContract(_vestingContract).release(_targetToken);
            return true;
        }
        return false;
    }

    function _releaseVesting (vestingContractVersion _version, address _vestingContract) internal returns (bool) {
        if (_version != vestingContractVersion.v1) {
            revert(&#39;You need to pass in the additional argument(s)&#39;);
        }
        IVestingContract(_vestingContract).release();
        return true;
    }

    function releaseVesting (vestingContractVersion _version, address _vestingContract, address _targetToken) public onlyOwner returns (bool) {
        return _releaseVesting(_version, _vestingContract, _targetToken);
    }

    function releaseVesting (vestingContractVersion _version, address _vestingContract) public onlyOwner returns (bool) {
        return _releaseVesting(_version, _vestingContract);
    }

    function release () public returns (bool){
        require(vestingContract != 0x0, &#39;Vesting Contract not set&#39;);
        return _releaseVesting(targetVersion, vestingContract, targetToken);
    }

    function () public {
      release();
    }
}

/**
* Allows using one call to both release and Distribute tokens from
* Handler and distributor in cases where separate contracts
* Presently does not support re-use
*/
contract VestingHasDistributorHandler is VestingHandler, HasDistributorHandler {

    constructor (distributorContractVersion _distributorVersion, address _tokenDistributor, vestingContractVersion _targetVersion, address _vestingContract, address _targetToken) public
    VestingHandler( _targetVersion, _vestingContract, _targetToken )
    HasDistributorHandler(_distributorVersion, _tokenDistributor)
    {
    }

    function releaseAndDistribute () public {
        release();
        distribute();
    }

    function () {
      releaseAndDistribute();
    }
}

contract VestingHasDistributorHandlerHasContracts is VestingHasDistributorHandler, HasContracts {

    constructor (distributorContractVersion _distributorVersion, address _tokenDistributor, vestingContractVersion _targetVersion, address _vestingContract, address _targetToken) public
    VestingHasDistributorHandler( _distributorVersion, _tokenDistributor, _targetVersion, _vestingContract, _targetToken )
    HasContracts()
    {
    }
}