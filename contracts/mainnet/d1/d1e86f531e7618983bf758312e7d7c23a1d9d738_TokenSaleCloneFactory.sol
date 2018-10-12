pragma solidity 0.4.24;

// File: contracts/TokenSaleInterface.sol

/**
 * @title TokenSale contract interface
 */
interface TokenSaleInterface {
    function init
    (
        uint256 _startTime,
        uint256 _endTime,
        address _whitelist,
        address _starToken,
        address _companyToken,
        uint256 _rate,
        uint256 _starRate,
        address _wallet,
        uint256 _crowdsaleCap,
        bool    _isWeiAccepted
    )
    external;
}

// File: contracts/cloneFactory/CloneFactory.sol

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  event CloneCreated(address indexed target, address clone);

  function createClone(address target) internal returns (address result) {
    bytes memory clone = hex"3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3";
    bytes20 targetBytes = bytes20(target);
    for (uint i = 0; i < 20; i++) {
      clone[20 + i] = targetBytes[i];
    }
    assembly {
      let len := mload(clone)
      let data := add(clone, 0x20)
      result := create(0, data, len)
    }
  }
}

// File: contracts/lib/Ownable.sol

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
    require(msg.sender == owner, "only owner is able to call this function");
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

// File: contracts/cloneFactory/TokenSaleCloneFactory.sol

contract TokenSaleCloneFactory is Ownable, CloneFactory {
    // TokenSale contract address for cloning purposes
    address public libraryAddress;
    address public starToken;

    mapping(address => bool) public isInstantiation;
    mapping(address => address[]) public instantiations;

    event ContractInstantiation(address msgSender, address instantiation);

    //
    /**
    * @dev set TokenSale contract clone as well as starToken upon deployment
    * @param _libraryAddress TokenSale contract address for cloning purposes
    * @param _starToken Star contract address in the _libraryAddress deployment
    */
    constructor(address _libraryAddress, address _starToken) public {
        require(
            _libraryAddress != address(0) && _starToken != address(0),
            "_libraryAddress and _starToken should not be empty!"
        );
        libraryAddress = _libraryAddress;
        starToken = _starToken;
    }

   /**
    * @dev Have the option of updating the TokenSale contract for cloning.
    * @param _libraryAddress Address for new contract
    */
    function setLibraryAddress(address _libraryAddress) external onlyOwner {
        require(_libraryAddress != address(0), "_libraryAddress should not be empty!");
        libraryAddress = _libraryAddress;
    }

    /**
     * @dev Returns number of instantiations by creator.
     * @param creator Contract creator.
     * @return Returns number of instantiations by creator.
     */
    function getInstantiationCount(address creator)
        public
        view
        returns (uint256)
    {
        return instantiations[creator].length;
    }

    /**
     * @dev Allows verified creation of pools.
     * @param _startTime The timestamp of the beginning of the crowdsale
     * @param _endTime Timestamp when the crowdsale will finish
     * @param _whitelist contract containing the whitelisted addresses
     * @param _companyToken ERC20 CompanyToken contract address
     * @param _rate The token rate per ETH
     * @param _starRate The token rate per STAR
     * @param _wallet Multisig wallet that will hold the crowdsale funds.
     * @param _crowdsaleCap Cap for the token sale
     * @param _isWeiAccepted Bool for acceptance of ether in token sale
     */
    function create
    (
        uint256 _startTime,
        uint256 _endTime,
        address _whitelist,
        address _companyToken,
        uint256 _rate,
        uint256 _starRate,
        address _wallet,
        uint256 _crowdsaleCap,
        bool    _isWeiAccepted
    )
        public
    {
        address tokenSale = createClone(libraryAddress);
        TokenSaleInterface(tokenSale).init(
            _startTime,
            _endTime,
            _whitelist,
            starToken,
            _companyToken,
            _rate,
            _starRate,
            _wallet,
            _crowdsaleCap,
            _isWeiAccepted
        );

        register(tokenSale);
    }

    /**
     * @dev Registers contract in factory registry.
     * @param instantiation Address of contract instantiation.
     */
    function register(address instantiation)
        internal
    {
        isInstantiation[instantiation] = true;
        instantiations[msg.sender].push(instantiation);

        emit ContractInstantiation(msg.sender, instantiation);
    }
}