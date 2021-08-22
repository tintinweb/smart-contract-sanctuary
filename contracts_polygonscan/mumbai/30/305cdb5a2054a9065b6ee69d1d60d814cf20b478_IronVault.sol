/**
 *Submitted for verification at polygonscan.com on 2021-08-21
*/

// SPDX-License-Identifier: MIT-0
pragma solidity =0.8.0;
pragma experimental ABIEncoderV2;

// Contracts needed: IronChef -> DfynRouter -> IronSwap -> IronChef

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IDFYNRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
}

interface IIronSwap {
    function addLiquidity(uint256[] memory amounts, uint256 minMintAmount, uint256 deadline) external returns (uint256);
    function removeLiquidity(uint256 lpAmount, uint256[] memory minAmounts, uint256 deadline) external returns (uint256);
}

interface IIronChef {
    function harvest(uint256 pid, address to) external;
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
}

contract IronVault {

    address public owner;
    IERC20 public ICE = IERC20(0x4A81f8796e0c6Ad4877A51C86693B0dE8093F2ef);
    IERC20 public IS3USD = IERC20(0xb4d09ff3dA7f9e9A2BA029cb0A81A989fd7B8f17);
    IERC20 public USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);


    IIronChef public IronChef;
    IDFYNRouter public DFYNRouter;
    IIronSwap public IronSwap;
    uint256 public slippage = 1;
    uint256 public pid;

    //events
    event OwnershipTransferred(address oldOwner, address newOwner);
    event UpdatePoolId(uint256 oldPool, uint256 newPool);

    // Initially set contract parameters and variables

    constructor(
        uint256 _pid,
        address _ironChef,
        address _ironSwap,
        address _iDfynRouter
        /*
        pid: 0
        ironchef: 0x1fD1259Fa8CdC60c6E8C86cfA592CA1b8403DFaD
        ironSwap: 0x837503e8a8753ae17fb8c8151b8e6f586defcb57
        dfynRouter: 0xa102072a4c07f06ec3b4900fdc4c7b80b6c57429
        */
    ) {
        owner = msg.sender;
        IronChef = IIronChef(_ironChef);
        DFYNRouter = IDFYNRouter(_iDfynRouter);
        IronSwap = IIronSwap(_ironSwap);
        // Customizable pool ID
        pid = _pid;


        // Unlimited approve token on RToken address
        // ICE.approve(address(RToken), 2**256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "IronFold: caller is not the owner");
        _;
    }
    

    function transferOwnership(address _owner) external onlyOwner {
        // Check if owner is different
        if (_owner != owner) {
            // Update owner and emit event
            address oldOwner = owner;
            owner = _owner;
            emit OwnershipTransferred(oldOwner, owner);
        }
    }

    function updatePoolId(uint256 _newPid) external onlyOwner {
        if (_newPid != pid) {
            //update pool id for iron farms
            uint256 oldPool = pid;
            pid = _newPid;
            emit UpdatePoolId(oldPool, pid);
        }
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "IronFold: external call failed");
        return result;
    }
}