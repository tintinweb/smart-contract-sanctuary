pragma solidity ^0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";

interface IUnitroller {
  function oracle() external view returns(address);
}
interface ICErc20 {
  function underlying() external view returns(address);
}

contract BeOneRegistry is Ownable {
    address private rewardToken;
    address private unitroller;
    address private dashboard;

    mapping(bytes32 => address) private interestRateModels;
    mapping(bytes32 => address) private cTokens;
    mapping(bytes32 => uint8) private tokensDecimalsToDisplay;
    mapping(bytes32 => address) private priceFeeds;
    bytes32[] private cTokenEncodedNames;

    event NewRewardToken(address rewardToken);
    event NewUnitroller(address unitroller);

    event NewDashboard(address dashboard);

    event NewInterestRateModel(address model);
    event InterestRateModelRemoved(string name);

    event NewCToken(address cToken);
    event CTokenRemoved(string name);

    event NewPriceFeed(address priceFeed);
    event PriceFeedRemoved(string name);

    function setRewardToken(address rewardTokenAddress)
        public
        onlyOwner
        returns (address)
    {
        require(
            rewardTokenAddress != address(0),
            "BEONE: address must not be 0"
        );
        require(rewardToken == address(0), "BEONE: reward token already set");
        rewardToken = rewardTokenAddress;
        emit NewRewardToken(rewardToken);
    }

    function getRewardToken() public view returns (address) {
        return rewardToken;
    }

    function setUnitroller(address unitrollerAddress)
        public
        onlyOwner
        returns (address)
    {
        require(
            unitrollerAddress != address(0),
            "BEONE: address must not be 0"
        );
        require(unitroller == address(0), "BEONE: unitroller already set");
        unitroller = unitrollerAddress;
        emit NewUnitroller(unitroller);
    }

    function getPriceOracleAddress() public view returns (address) {
        return IUnitroller(unitroller).oracle();
    }

    function getUnitrollerAddress() public view returns (address) {
        return unitroller;
    }

    function setDashboard(address dashboardAddress)
        public
        onlyOwner
        returns (address)
    {
        require(dashboardAddress != address(0), "BEONE: address must not be 0");
        require(dashboard == address(0), "BEONE: dashboard already set");
        dashboard = dashboardAddress;
        emit NewDashboard(dashboard);
    }

    function getDashboard() public view returns (address) {
        return dashboard;
    }

    function addInterestRateModel(
        string memory name,
        address interestRateModelAddress
    ) public onlyOwner {
        require(
            interestRateModelAddress != address(0),
            "BEONE: address must not be 0"
        );
        require(
            interestRateModels[sha256(abi.encodePacked(name))] == address(0),
            "BEONE: interest rate model already set"
        );

        interestRateModels[sha256(
            abi.encodePacked(name)
        )] = interestRateModelAddress;
        emit NewInterestRateModel(interestRateModelAddress);
    }

    function removeInterestRateModel(string memory name) public onlyOwner {
        require(
            interestRateModels[sha256(abi.encodePacked(name))] != address(0),
            "BEONE: remove unknown interest rate model"
        );

        delete interestRateModels[sha256(abi.encodePacked(name))];
        emit InterestRateModelRemoved(name);
    }

    function getInterestRateModel(string memory name)
        public
        view
        returns (address)
    {
        return interestRateModels[sha256(abi.encodePacked(name))];
    }

    function addCToken(string memory name, address cTokenAddress, uint8 tokenDecimalsToDisplay)
        public
        onlyOwner
    {
        require(cTokenAddress != address(0), "BEONE: address must not be 0");
        require(
            cTokens[sha256(abi.encodePacked(name))] == address(0),
            "BEONE: cToken already set"
        );
        bytes32 cTokenEncodedName = sha256(abi.encodePacked(name));
        cTokens[cTokenEncodedName] = cTokenAddress;
        tokensDecimalsToDisplay[cTokenEncodedName] = tokenDecimalsToDisplay;
        cTokenEncodedNames.push(cTokenEncodedName);
        emit NewCToken(cTokenAddress);
    }

    function removeCToken(string memory name) public onlyOwner {
        require(
            cTokens[sha256(abi.encodePacked(name))] != address(0),
            "BEONE: removing unknown cToken"
        );

        bytes32 cTokenEncodedName = sha256(abi.encodePacked(name));
        // TODO: loop over cTokenEncodedName to delete
        delete cTokens[cTokenEncodedName];
        delete tokensDecimalsToDisplay[cTokenEncodedName];
        emit CTokenRemoved(name);
    }

    function getTokenDecimalsToDisplay(string memory name) public view returns (uint8) {
        return tokensDecimalsToDisplay[sha256(abi.encodePacked(name))];
    }

    function getCToken(string memory name) public view returns (address) {
        return cTokens[sha256(abi.encodePacked(name))];
    }
    function getToken(string memory name) public view returns (address) {
        return ICErc20(cTokens[sha256(abi.encodePacked(name))]).underlying();
    }


    function addUnderlyingPriceFeed(
        string memory name,
        address priceFeedAddress
    ) public onlyOwner {
        require(
            priceFeeds[sha256(abi.encodePacked(name))] == address(0),
            "BEONE: priceFeed already set"
        );
        bytes32 cTokenEncodedName = sha256(abi.encodePacked(name));
        priceFeeds[cTokenEncodedName] = priceFeedAddress;
        emit NewPriceFeed(priceFeedAddress);
    }

    function removeUnderlyingPriceFeed(string memory name) public onlyOwner {
        require(
            priceFeeds[sha256(abi.encodePacked(name))] != address(0),
            "BEONE: removing unknown PriceFeed"
        );

        bytes32 cTokenEncodedName = sha256(abi.encodePacked(name));
        // TODO: loop over cTokenEncodedName to delete
        delete priceFeeds[cTokenEncodedName];
        emit PriceFeedRemoved(name);
    }

    function getUnderlyingPriceFeed(string memory name)
        public
        view
        returns (address)
    {
        return priceFeeds[sha256(abi.encodePacked(name))];
    }

  function getCtokenAddressByIndex(uint256 index)
    public
    view
    returns (address)
  {
    return cTokens[cTokenEncodedNames[index]];
  }

    function getCTokensLength() public view returns (uint256) {
        return cTokenEncodedNames.length;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}