/**
 *Submitted for verification at snowtrace.io on 2021-12-29
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IPangolinRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IHermesMasterchef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
}

contract HermesHSHARE_Compounder {
    address public owner;
    address public admin;
    uint256 public pid;
    IERC20 public HSHARES = IERC20(0xfa4B6db72A650601E7Bd50a0A9f537c9E98311B2);
    IERC20 public WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public PLP = IERC20(0xC132ff3813De33356C859979501fB212673e395e);

    IPangolinRouter public router = IPangolinRouter(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
    IHermesMasterchef public masterchef = IHermesMasterchef(0xDDd0A62D8e5AFeccFB334e49D27a57713DD0fBcc);

    constructor(uint256 _pid, address _admin) {
        owner = msg.sender;
        admin = _admin;
        pid = _pid;
        HSHARES.approve(address(router), 2 ** 256 - 1);
        WAVAX.approve(address(router), 2 ** 256 - 1);
        PLP.approve(address(masterchef), 2 ** 256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Compounder: Caller is not the deployer");
        _;
    }

    modifier onlyAdmin {
        require(owner == msg.sender || admin == msg.sender, "Compounder: Caller is not an admin address");
        _;
    }

    function deposit() public onlyOwner {
        require(PLP.balanceOf(address(this)) > 0, "Compounder: Insufficient LP balance");
        masterchef.deposit(pid, PLP.balanceOf(address(this)));
    }

    function harvest() public {
        masterchef.deposit(pid, 0);
    }

    function withdraw() external onlyOwner {
        harvest();
        masterchef.emergencyWithdraw(pid);
        PLP.transfer(owner, PLP.balanceOf(address(this)));
        HSHARES.transfer(owner, HSHARES.balanceOf(address(this)));
    }

    function compound() external onlyAdmin {
        harvest();

        address[] memory path = new address[](2);
        path[0] = address(HSHARES);
        path[1] = address(WAVAX);
        router.swapExactTokensForTokens(
            HSHARES.balanceOf(address(this)) / 2,
            0,
            path,
            address(this),
            block.timestamp + 1200
        );

        router.addLiquidity(
            address(HSHARES),
            address(WAVAX),
            HSHARES.balanceOf(address(this)),
            WAVAX.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1200
        );

        deposit();
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "Compounder: external call failed");
        return result;
    }
}