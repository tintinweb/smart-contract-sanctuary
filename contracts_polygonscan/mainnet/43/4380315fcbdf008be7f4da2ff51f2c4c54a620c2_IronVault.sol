/**
 *Submitted for verification at polygonscan.com on 2021-08-21
*/

// SPDX-License-Identifier: MIT-0
pragma solidity =0.8.0;
pragma experimental ABIEncoderV2;

// Contracts needed: IronChef -> DfynRouter -> IronSwap -> IronChef
// "IronVault: Error Message"

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IDFYNRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IIronSwap {
    function addLiquidity(uint256[] memory amounts, uint256 minMintAmount, uint256 deadline) external returns (uint256);
    function removeLiquidity(uint256 lpAmount, uint256[] memory minAmounts, uint256 deadline) external returns (uint256);
}

interface IIronChef {
    function harvest(uint256 pid, address to) external;
    function deposit(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
}

contract IronVault {

    address public owner;
    IERC20 public ICE = IERC20(0x4A81f8796e0c6Ad4877A51C86693B0dE8093F2ef);
    IERC20 public IS3USD = IERC20(0xb4d09ff3dA7f9e9A2BA029cb0A81A989fd7B8f17);
    IERC20 public USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);


    IIronChef public IronChef = IIronChef(0x1fD1259Fa8CdC60c6E8C86cfA592CA1b8403DFaD);
    IDFYNRouter public DFYNRouter = IDFYNRouter(0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429);
    IIronSwap public IronSwap = IIronSwap(0x837503e8A8753ae17fB8C8151B8e6f586defCb57);
    uint256 public slippage = 1; // Solidity does not support decimals
    uint256 public pid;

    // time for unix timestamps
    uint constant TWENTY_MINUTES = 1200; // in seconds

    //events
    event OwnershipTransferred(address oldOwner, address newOwner);
    event UpdatePoolId(uint256 oldPool, uint256 newPool);

    // Initially set contract parameters and variables

    constructor(
        uint256 _pid
        /*
        address _ironChef,
        address _ironSwap,
        address _iDfynRouter
        
        pid: 0
        ironchef: 0x1fD1259Fa8CdC60c6E8C86cfA592CA1b8403DFaD
        ironSwap: 0x837503e8A8753ae17fB8C8151B8e6f586defCb57
        dfynRouter: 0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429
        */
    ) {
        owner = msg.sender;
        /*
        IronChef = IIronChef(_ironChef);
        DFYNRouter = IDFYNRouter(_iDfynRouter);
        IronSwap = IIronSwap(_ironSwap);
        */
        // Customizable pool ID
        pid = _pid;


        // Unlimited approve token on RToken address
        ICE.approve(address(DFYNRouter), 2**256 - 1);
        USDC.approve(address(IronSwap), 2**256 - 1);
        IS3USD.approve(address(IronChef), 2**256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "IronVault: caller is not the owner");
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

    function deposit() public onlyOwner {
        // send IS3USD tokens into pool 0 (stable pool)
        require(IS3USD.balanceOf(address(this)) != 0, "IronVault: No IS3USD tokens to deposit");
        IronChef.deposit(pid, IS3USD.balanceOf(address(this)), address(this));
    }

    /*
    function compound() public onlyOwner {
        // claim ICE, swap ICE for USDC
        // TODO: Deposit USDC into IronSwap LP function to recieve IS3USD Tokens
        // TODO: Stake IS3USD into IronChef, compound complete.
        claimReward();
        DFYNRouter.swapExactTokensForTokens(
            ICE.balanceOf(address(this)),
            //PLACEHOLDER,
            [address(ICE), address(USDC)],
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }
    function getUSDPayAmount() internal returns (uint256) {
        DFYNRouter.getAmountsOut(ICE.balanceOf(address(this)), [0x4A81f8796e0c6Ad4877A51C86693B0dE8093F2ef, 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174]);
    }
    */

    function claimReward() public onlyOwner {
        IronChef.harvest(pid, address(this));
    }

    function emergencyClaimReward() public onlyOwner {
        // claim rewards and directly send all ICE tokens to owner address
        IronChef.harvest(pid, address(this));
        ICE.transfer(owner, ICE.balanceOf(address(this)));
    }

    function withdrawFromIron() public onlyOwner {
        IronChef.harvest(0, address(this));
        IronChef.emergencyWithdraw(pid, address(this));
    }

    function emergencyWithdrawFromIron() public onlyOwner {
        IronChef.harvest(0, address(owner));
        IronChef.emergencyWithdraw(pid, address(owner));
    }

    function emergencyWithdrawToken(address _tokenContract) external onlyOwner {
        // in case functions do not work, manually withdraw standard tokens from the contract.
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract to the owner
        tokenContract.transfer(owner, tokenContract.balanceOf(address(this)));
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "IronVault: external call failed");
        return result;
    }
}