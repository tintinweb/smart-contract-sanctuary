// StrategyProxy: https://etherscan.io/address/0x5886e475e163f78cf63d6683abc7fe8516d12081#code
pragma solidity ^0.6.7;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "./crv-locker.sol";

import "../../interfaces/curve.sol";

contract SCRVVoter {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    CRVLocker public crvLocker;

    address public constant want = 0xC25a3A3b969415c80451098fa907EC722572917F;
    address public constant mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant snx = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address
        public constant gaugeController = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB;
    address
        public constant scrvGauge = 0xA90996896660DEcC6E997655E065b23788857849;

    mapping(address => bool) public strategies;
    address public governance;

    constructor(address _governance, address _crvLocker) public {
        governance = _governance;
        crvLocker = CRVLocker(_crvLocker);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function approveStrategy(address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategies[_strategy] = true;
    }

    function revokeStrategy(address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategies[_strategy] = false;
    }

    function lock() external {
        crvLocker.increaseAmount(IERC20(crv).balanceOf(address(crvLocker)));
    }

    function vote(address _gauge, uint256 _amount) public {
        require(strategies[msg.sender], "!strategy");
        crvLocker.execute(
            gaugeController,
            0,
            abi.encodeWithSignature(
                "vote_for_gauge_weights(address,uint256)",
                _gauge,
                _amount
            )
        );
    }

    function max() external {
        require(strategies[msg.sender], "!strategy");
        vote(scrvGauge, 10000);
    }

    function withdraw(
        address _gauge,
        address _token,
        uint256 _amount
    ) public returns (uint256) {
        require(strategies[msg.sender], "!strategy");
        uint256 _before = IERC20(_token).balanceOf(address(crvLocker));
        crvLocker.execute(
            _gauge,
            0,
            abi.encodeWithSignature("withdraw(uint256)", _amount)
        );
        uint256 _after = IERC20(_token).balanceOf(address(crvLocker));
        uint256 _net = _after.sub(_before);
        crvLocker.execute(
            _token,
            0,
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                _net
            )
        );
        return _net;
    }

    function balanceOf(address _gauge) public view returns (uint256) {
        return IERC20(_gauge).balanceOf(address(crvLocker));
    }

    function withdrawAll(address _gauge, address _token)
        external
        returns (uint256)
    {
        require(strategies[msg.sender], "!strategy");
        return withdraw(_gauge, _token, balanceOf(_gauge));
    }

    function deposit(address _gauge, address _token) external {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(address(crvLocker), _balance);

        _balance = IERC20(_token).balanceOf(address(crvLocker));
        crvLocker.execute(
            _token,
            0,
            abi.encodeWithSignature("approve(address,uint256)", _gauge, 0)
        );
        crvLocker.execute(
            _token,
            0,
            abi.encodeWithSignature(
                "approve(address,uint256)",
                _gauge,
                _balance
            )
        );
        crvLocker.execute(
            _gauge,
            0,
            abi.encodeWithSignature("deposit(uint256)", _balance)
        );
    }

    function harvest(address _gauge) external {
        require(strategies[msg.sender], "!strategy");
        uint256 _before = IERC20(crv).balanceOf(address(crvLocker));
        crvLocker.execute(
            mintr,
            0,
            abi.encodeWithSignature("mint(address)", _gauge)
        );
        uint256 _after = IERC20(crv).balanceOf(address(crvLocker));
        uint256 _balance = _after.sub(_before);
        crvLocker.execute(
            crv,
            0,
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                _balance
            )
        );
    }

    function claimRewards() external {
        require(strategies[msg.sender], "!strategy");

        uint256 _before = IERC20(snx).balanceOf(address(crvLocker));
        crvLocker.execute(scrvGauge, 0, abi.encodeWithSignature("claim_rewards()"));
        uint256 _after = IERC20(snx).balanceOf(address(crvLocker));
        uint256 _balance = _after.sub(_before);

        crvLocker.execute(
            snx,
            0,
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                _balance
            )
        );
    }
}
