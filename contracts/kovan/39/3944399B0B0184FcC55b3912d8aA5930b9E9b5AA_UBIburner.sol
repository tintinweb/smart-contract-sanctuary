/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

/**
 * @title UniswapV2Router Interface
 * @dev See https://uniswap.org/docs/v2/smart-contracts/router02/#swapexactethfortokens. This will allow us to import swapExactETHForTokens function into our contract and the getAmountsOut function to calculate the token amount we will swap
 */
interface IUniswapV2Router {
    function swapExactETHForTokens(
        uint256 amountOutMin, //minimum amount of output token that must be received
        address[] calldata path, //the different hops between tokens to be made by the exchange
        address to, //recipient
        uint256 deadline //unix timestamp after which the transaction will revert
    )
        external
        payable
        returns (
            uint256[] memory amounts //amounts of tokens output received
        );

    function getAmountsOut(
        uint256 amountIn, //amount of input token
        address[] memory path //the different hops between tokens to be made by the exchange
    )
        external
        view
        returns (
            uint256[] memory amounts //amounts of tokens output calculated to be received
        );
}

/**
 * @title UBI Interface
 * @dev See https://github.com/DemocracyEarth/ubi/blob/master/contracts/UBI.sol This will allow us to see the UBI balance of our contract (burned UBI)
 */
interface IUBI {
    function balanceOf(address _owner) external view returns (uint256);
}

contract UBIburner {
    event Received(address indexed from, uint256 amount);
    event Burned(address indexed burner, uint256 amount);
    event BurnerAdded(address burner);
    event BurnerRemoved(address burner);
    event BurnUBIRequested(address requester, uint256 UBIAmount);

    /// @dev address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /// @dev address of WETH token. In Uniswap v2 there are no more direct ETH pairs, all ETH must be converted to WETH first.
    address private constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    /// @dev address of UBI token.
    address private constant UBI = 0xDdAdE19B13833d1bF52c1fe1352d41A8DD9fE8C9;

    /// @dev An array of token addresses. Any swap needs to have a starting and end path, path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
    address[] path = [WETH, UBI];

    /// @dev Parameter stored by the burner request of how much the minimum amount of UBIs burned should be.
    uint256 public currentAmountOutMin;

    /// @dev Burn requester. Variable stored because the burner cannot be the requester.
    address public currentBurnRequester;

    /// @dev Indicates if the address belongs to a burner. isBurner[address].
    mapping(address => bool) public isBurner;

    /// @dev Indicates whether or not there is a request to add a new burner. requestBurnerAddMap[requesterAddress][burnerAddressToAdd].
    mapping(address => mapping(address => bool)) public requestBurnerAddMap;

    /// @dev Indicates whether or not there is a request to remove a burner. requestBurnerRemovalMap[requesterAddress][burnerAddressToRemove].
    mapping(address => mapping(address => bool)) public requestBurnerRemovalMap;

    /// @dev 3 burners will be created by the constructor
    constructor(address _burner2, address _burner3) {
        addBurner(msg.sender); //_burner1
        addBurner(_burner2);
        addBurner(_burner3);
    }

    modifier onlyBurner() {
        require(isBurner[msg.sender], "Not burner");
        _;
    }

    /** @dev Internal function to create a burner and emit an event.
     *  @param _burner Burner to add.
     */
    function addBurner(address _burner) internal {
        isBurner[_burner] = true;
        emit BurnerAdded(_burner);
    }

    /** @dev Internal function to remove a burner and emit an event.
     *  @param _burner Burner to delete.
     */
    function removeBurner(address _burner) internal {
        isBurner[_burner] = false;
        emit BurnerRemoved(_burner);
    }

    /** @dev Requests the creation of a new burner.
     *  @param _burnerToAdd Address of the burner requested to be added.
     */
    function requestBurnerAdd(address _burnerToAdd) external onlyBurner {
        requestBurnerAddMap[msg.sender][_burnerToAdd] = true;
    }

    /** @dev Acceptance of the new burner by another burner.
     *  @param _requester Requester address.
     *  @param _burnerToAdd Address of the burner to be accepted.
     */
    function AddBurnerAccepted(address _requester, address _burnerToAdd)
        external
        onlyBurner
    {
        require(
            !requestBurnerAddMap[msg.sender][_burnerToAdd] &&
                requestBurnerAddMap[_requester][_burnerToAdd]
        );
        requestBurnerAddMap[_requester][_burnerToAdd] = false;
        addBurner(_burnerToAdd);
    }

    /** @dev Requests the removal of a burner.
     *  @param _burnerToRemove Address of the burner requested to be removed.
     */
    function requestBurnerRemoval(address _burnerToRemove) external onlyBurner {
        requestBurnerRemovalMap[msg.sender][_burnerToRemove] = true;
    }

    /** @dev Acceptance of the burner to be removed.
     *  @param _requester Requester address.
     *  @param _burnerToRemove Address of the burner to be removed.
     */
    function deleteBurnerAccepted(address _requester, address _burnerToRemove)
        external
        onlyBurner
    {
        require(
            !requestBurnerRemovalMap[msg.sender][_burnerToRemove] &&
                requestBurnerRemovalMap[_requester][_burnerToRemove]
        );
        requestBurnerRemovalMap[_requester][_burnerToRemove] = false;
        isBurner[_burnerToRemove] = false;
    }

    /// @dev UBI burn request. This stores the parameters to be used when another burner accepts. Can be recalled to update the values
    function requestBurnUBI() external onlyBurner {
        currentAmountOutMin = getAmountOutMin();
        currentBurnRequester = msg.sender;
        emit BurnUBIRequested(msg.sender, currentAmountOutMin);
    }

    /** @dev Using the parameters stored by the requester, this function buys UBI with the ETH contract balance and freezes on this contract.
     *  @param _deadline Unix timestamp after which the transaction will revert.
     */
    function burnUBI(uint256 _deadline) external onlyBurner {
        uint256 _balanceToBurn = address(this).balance;
        uint256 _amountOutMin = currentAmountOutMin;
        // 0.5% less to avoid tx failure due to price decrease between request and approval
        uint256 _amountOutMinToUse = _amountOutMin - (_amountOutMin / 200);
        address _burnRequester = currentBurnRequester;
        require(_burnRequester != msg.sender && _burnRequester != address(0));
        currentAmountOutMin = 0;
        currentBurnRequester = address(0);
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactETHForTokens{
            value: _balanceToBurn
        }(_amountOutMinToUse, path, address(this), _deadline);
        emit Burned(msg.sender, _balanceToBurn);
    }

    /** @dev Calculate the minimum UBI amount from swapping the ETH contract balance.
     *  @return The minimum amount of output token that must be received.
     */
    function getAmountOutMin() public view returns (uint256) {
        if (address(this).balance == 0) return 0;
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(address(this).balance, path);
        return amountOutMins[1];
    }

    /** @dev UBI contract balance (burned UBI).
     *  @return The amount of UBI burned.
     */
    function UBIburned() external view returns (uint256) {
        return IUBI(UBI).balanceOf(address(this));
    }

    /// @dev Allows the contract to receive ETH
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}