// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IATokenV1.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./ILendingPoolV1.sol";
import "./ICompoundLens.sol";
import "./IUniswapV2.sol";
import "./IBasicIssuanceModule.sol";
import "./IOneInch.sol";

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./BMIZapper.sol";

// Basket Weaver is a way to socialize gas costs related to minting baskets tokens
contract SocialBMIZapper is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public governance;
    address public bmi;
    address public bmiZapper;

    // **** ERC20 **** //

    // Token => Id
    mapping(address => uint256) public curId;

    // Token => User Address => Id => Amount deposited
    mapping(address => mapping(address => mapping(uint256 => uint256))) public deposits;

    // Token => User Address => Id => Claimed
    mapping(address => mapping(address => mapping(uint256 => bool))) public claimed;

    // Token => Id => Amount deposited
    mapping(address => mapping(uint256 => uint256)) public totalDeposited;

    // Token => Basket minted per weaveId
    mapping(address => mapping(uint256 => uint256)) public minted;

    // Approved users to call weave
    // This is v important as invalid inputs will
    // be basically a "fat finger"
    mapping(address => bool) public approvedWeavers;

    // **** Constructor and modifiers ****

    constructor(
        address _governance,
        address _bmi,
        address _bmiZapper
    ) {
        governance = _governance;
        bmi = _bmi;
        bmiZapper = _bmiZapper;
    }

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyWeavers {
        require(msg.sender == governance || approvedWeavers[msg.sender], "!weaver");
        _;
    }

    receive() external payable {}

    // **** Protected functions ****

    function approveWeaver(address _weaver) public onlyGov {
        approvedWeavers[_weaver] = true;
    }

    function revokeWeaver(address _weaver) public onlyGov {
        approvedWeavers[_weaver] = false;
    }

    function setGov(address _governance) public onlyGov {
        governance = _governance;
    }

    // Emergency
    function recoverERC20(address _token) public onlyGov {
        IERC20(_token).safeTransfer(governance, IERC20(_token).balanceOf(address(this)));
    }

    function socialZap(
        address _from,
        address _fromUnderlying,
        uint256 _fromUnderlyingAmount,
        uint256 _minBMIRecv,
        address[] memory _bmiConstituents,
        uint256[] memory _bmiConstituentsWeightings,
        address _aggregator,
        bytes memory _aggregatorData,
        uint256 deadline
    ) public onlyWeavers {
        require(block.timestamp <= deadline, "expired");

        uint256 _fromAmount = IERC20(_from).balanceOf(address(this));

        IERC20(_from).safeApprove(bmiZapper, 0);
        IERC20(_from).safeApprove(bmiZapper, _fromAmount);

        uint256 bmiMinted =
            BMIZapper(bmiZapper).zapToBMI(
                _from,
                _fromAmount,
                _fromUnderlying,
                _fromUnderlyingAmount,
                _minBMIRecv,
                _bmiConstituents,
                _bmiConstituentsWeightings,
                _aggregator,
                _aggregatorData,
                true
            );

        minted[_from][curId[_from]] = bmiMinted;

        curId[_from]++;
    }

    // **** Public functions ****

    /// @notice Deposits ERC20 to be later converted into the Basket by some kind soul
    function deposit(address _token, uint256 _amount) public nonReentrant {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        deposits[_token][msg.sender][curId[_token]] = deposits[_token][msg.sender][curId[_token]].add(_amount);
        totalDeposited[_token][curId[_token]] = totalDeposited[_token][curId[_token]].add(_amount);
    }

    /// @notice User doesn't want to wait anymore and just wants their ERC20 back
    function withdraw(address _token, uint256 _amount) public nonReentrant {
        // Reverts if withdrawing too many
        deposits[_token][msg.sender][curId[_token]] = deposits[_token][msg.sender][curId[_token]].sub(_amount);
        totalDeposited[_token][curId[_token]] = totalDeposited[_token][curId[_token]].sub(_amount);

        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// @notice User withdraws converted Basket token
    function withdrawBMI(address _token, uint256 _id) public nonReentrant {
        require(_id < curId[_token], "!weaved");
        require(!claimed[_token][msg.sender][_id], "already-claimed");
        uint256 userDeposited = deposits[_token][msg.sender][_id];
        require(userDeposited > 0, "!deposit");

        uint256 ratio = userDeposited.mul(1e18).div(totalDeposited[_token][_id]);
        uint256 userBasketAmount = minted[_token][_id].mul(ratio).div(1e18);
        claimed[_token][msg.sender][_id] = true;

        IERC20(address(bmi)).safeTransfer(msg.sender, userBasketAmount);
    }

    /// @notice User withdraws converted Basket token
    function withdrawBMIMany(address[] memory _tokens, uint256[] memory _ids) public {
        assert(_tokens.length == _ids.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            withdrawBMI(_tokens[i], _ids[i]);
        }
    }
}