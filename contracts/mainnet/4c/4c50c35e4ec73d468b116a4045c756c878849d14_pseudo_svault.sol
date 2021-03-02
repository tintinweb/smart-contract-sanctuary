/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint bountyValue) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint bountyValue) external returns (bool);
    function transferFrom(address sender, address recipient, uint bountyValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface UniswapRouter {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory);
}

interface YCrvGauge {
    function deposit(uint256 bountyValue) external;
    function withdraw(uint256 bountyValue) external;
}

interface TokenMinter {
    function mint(address account) external;
}



// import relevant packages/package functions like SafeMath, Address, SafeERC20
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
   

// Implement FLOW (see the README)
contract pseudo_svault {

    using SafeMath for uint256;

    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    UniswapRouter constant UNIROUTER = UniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  //UniswapV2Router02 is deployed here; https://uniswap.org/docs/v2/smart-contracts/router02/
    YCrvGauge constant YCRVGAUGE = YCrvGauge(0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1);
    IERC20 constant CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    TokenMinter constant TOKENMINTER = TokenMinter(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    // create struct Bounty
    struct Bounty {
        uint256 bountyValue;
        uint256 bountyTimeStamp;
        uint256 totalBountyDeposit;
    }

    // declare mappings
    mapping(address => uint) public _rewardedBalancePerUser;
    mapping(address => uint) public _lastTimestampPerUser;
    mapping(address => uint) public _depositBalancePerUser;

    uint256 public _totalBountyDeposit;

    Bounty[] public _bounties;

    string public vaultName;
    address public vaultAddress;

    IERC20 public token0;
    IERC20 public token1; // PF deployer address

    address public feeAddress;
    uint32 public feeRate;
    address public treasury;

    bool public isWithdrawable;

    // based on convo with Ali the user rate should be 70%, treasury rate 30%; total rate is 10000 or 100%
    uint256 public rewardUserRate = 7000;
    uint32 public rewardTreasuryRate = 3000;
    // may want totalRate to be constant rather than public
    uint256 public totalRate = 10000;
    
    uint256 public crv_0;
    uint256 public token_0;
    
    address public gov;

    // declare events; same as OG contract but also has an event for the sent bounty
    event Deposited(address indexed user, uint256 bountyValue);
    event ClaimedReward(address indexed user, uint256 bountyValue);
    event Withdrawn(address indexed user, uint256 bountyValue);
    event DistributedBounty(address indexed, uint256 bountyValue);

    // implement constructor
    // might get rid of _vaultAddress
    constructor (address _token0, address _token1, address _feeAddress, string memory name, address _treasury) payable {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        feeAddress = _feeAddress;
        vaultName = name;
        gov = msg.sender;
        treasury = _treasury;
        token0.approve(address(YCRVGAUGE), type(uint).max);
        CRV.approve(address(UNIROUTER), type(uint).max);
        // token0.approve(address(YCRVGAUGE), 100);
        // CRV.approve(address(UNIROUTER), 100);
    }

    modifier onlyGov() {
        require(msg.sender == gov, "!governance");
        _;
    }

    function setGovernance(address _gov)
        external
        onlyGov
    {
        gov = _gov;
    }

    function setToken0(address _token)
        external
        onlyGov
    {
        token0 = IERC20(_token);
    }

    function setToken1(address _token)
        external
        onlyGov
    {
        token1 = IERC20(_token);
    }

    function setTreasury(address _treasury)
        external
        onlyGov
    {
        treasury = _treasury;
    }

    function setUserRate(uint256 _rewardUserRate)
        external
        onlyGov
    {
        rewardUserRate = _rewardUserRate;
    }

    function setTreasuryRate(uint32 _rewardTreasuryRate)
        external
        onlyGov
    {
        rewardTreasuryRate = _rewardTreasuryRate;
    }

    function setFeeAddress(address _feeAddress)
        external
        onlyGov
    {
        feeAddress = _feeAddress;
    }

    function setFeeRate(uint32 _feeRate)
        external
        onlyGov
    {
        feeRate = _feeRate;
    }

    function setWithdrawable(bool _isWithdrawable)
        external
        onlyGov
    {
        isWithdrawable = _isWithdrawable;
    }

    function setVaultName(string memory name)
        external
        onlyGov
    {
        vaultName = name;
    }

    function setTotalRate(uint256 _totalRate)
        external
        onlyGov
    {
        totalRate = _totalRate;
    }
    
    // function makeCRV() internal {
    //     uint rewardAmountForCRVToken = CRV.balanceOf(address(this));
    //     TOKENMINTER.mint(address(YCRVGAUGE));
    //     rewardAmountForCRVToken = CRV.balanceOf(address(this)) - rewardAmountForCRVToken;
    // }

    // I modified getReward() such that updating rewardedBalance is greatly simplifed 
    // this is similar structure to the modifier updateBalance() in original contract but makes use of
    // SafeMath as well as the Bounty struct (_bounties) for easier access of specific public information
    // rewardedBalance is updated by adding the:
    // (bountyValue ((rewardvaleeForCRVToken) * _depositBalancePerUser[userAddress]) / _bounties[k].totalBountyDeposit)
    function getReward(address userAddress) internal {

        uint256 rewardedBalance = _rewardedBalancePerUser[userAddress];
        uint256 lastTimestamp = _lastTimestampPerUser[userAddress];

        // make sure timestamp & _bounties struct is larger than 0 in order to avoid processing dud calls 
        // lastTimestamp of user's address must be less than previous user's
        if (lastTimestamp > 0 && _bounties.length > 0) {
            for (uint k = _bounties.length - 1; lastTimestamp < _bounties[k].bountyTimeStamp; k--) {
                rewardedBalance = rewardedBalance.add(_bounties[k].bountyValue.mul(_depositBalancePerUser[userAddress]).div(_bounties[k].totalBountyDeposit));
                if (k == 0) break; // break for loop if k is 0 to avoid unnessecary runtime
            }
        }
        _rewardedBalancePerUser[userAddress] = rewardedBalance;
        _lastTimestampPerUser[msg.sender] = block.timestamp;
    }

    // function deposit(uint amount) external updateBalance(msg.sender) --> shouldn't need this since getReward is called each time which acts
    // in exact same capacity as updateBalance() in OG contract; getReward from OG contract is very inefficient and has been split up in this contract 
    
    // bountyValue is in yCRV when user deposits
    function deposit(uint256 bountyValue) external {
        getReward(msg.sender);

        uint256 feebountyValue = bountyValue.mul(feeRate).div(totalRate); 
       
        // actual amount being deposited after fee is assessed       
        uint256 realbountyValue = bountyValue.sub(feebountyValue);
        
        if (feebountyValue > 0) {
            token0.transferFrom(msg.sender, feeAddress, feebountyValue);
        }

        // vaultAddress is used here instead of address(this) in original contract because we want to deposit to vault
        // address(this) [address of the contract instance] might make more sense if the this is deployed by PF
        // actual amount being deposited into PF's yUSD vault after fee is assessed 

        // address(this) since this is actually just transferring the yCRV to the contract instance who then deposits
        if (realbountyValue > 0) {
            token0.transferFrom(msg.sender, address(this), realbountyValue);
            YCRVGAUGE.deposit(realbountyValue); // -> does this need to be done here or will vaultAddress handle depositing this to ycrvguage?
            _depositBalancePerUser[msg.sender] = _depositBalancePerUser[msg.sender].add(realbountyValue);  // use _depositBalancePerUser from mapping
            _totalBountyDeposit = _totalBountyDeposit.add(realbountyValue); // update _totalBountyDeposit
            emit Deposited(msg.sender, realbountyValue);
        }
    }

    // PF is withdrawing from yUSD or CRV on behalf of user
    // msg.sender in this case is PF's address I believe...might use userAddress instead of msg.sender
    function withdraw(uint256 bountyValue) external {
        // again make sure there is something to withdraw to avoid dud calls

        // require(token0.balanceOf(address(this)) > 0, "nothing to withdraw");
        require(isWithdrawable, "not withdrawable");

        getReward(msg.sender);

        // if the bountyValue is larger than the user's balance then we'll reset the bountyValue to the user's actual balance
        if (bountyValue > _depositBalancePerUser[msg.sender]) {
            bountyValue = _depositBalancePerUser[msg.sender];
        }

        // again making sure to avoid continuing if there's nothing to withdraw after reseting bountyValue
        require(bountyValue > 0, "withdraw amount is 0");

        YCRVGAUGE.withdraw(bountyValue);

        // transfer CRV tokens to PF, the sender
        token0.transfer(msg.sender, bountyValue);

        // assign deposit balance to the deposit balance minus the bountyValue (the amount needed to be withdrawn for YCRV)
        _depositBalancePerUser[msg.sender] = _depositBalancePerUser[msg.sender].sub(bountyValue);
        //update public total bounty deposit value such that bountyValue needed to be withdrawn for YCRV is withdrawn
        _totalBountyDeposit = _totalBountyDeposit.sub(bountyValue);  // seems like full amount should be withdrawn

        emit Withdrawn(msg.sender, bountyValue);
    }


    // making a new separate function to actually send the bounty and send to treasury (called by PF)
    // this function is called last once the user claimReward() has been called
    // this function uses logic from the getReward() in the original contract
    // and is a cleaner implementation
    function _distributeBounty(uint256 maxBountyValue) internal returns (uint256, uint256) {
        // again make sure there is a bounty vaue to give in order to avoid dud calls
        require(maxBountyValue > 0, "bountyValue can't be 0");
        require(_totalBountyDeposit > 0, "totalDeposit must bigger than 0");


        uint256 treasuryBountyValue; 
        uint256 bountyValueUser = maxBountyValue.mul(rewardUserRate).div(totalRate);  // bountyValueUser == rewardCRVTokenAmountForUsers in original contract (i.e. rewardAmountForCRVToken * rewardUserRate / TOTALRATE)
        treasuryBountyValue = maxBountyValue.sub(bountyValueUser);  // update bountyValue (amountWithdrawForYCRV) by subtracting bountyValueUser (rewardCRVTokenAmountForUsers)
        
        // perform swap here --> need to assess what swapExactTokensForTokens() call takes as args

        // somthing like UNIROUTER.swapExactTokensForTokens(rewardCRVTokenAmountForUsers, 0, tokens, address(this), type(uint).max);
        // where tokens is an array that has CRV, WETH, and token1
        // this call will update token1
        address[] memory tokens = new address[](3);
        tokens[0] = address(CRV);
        tokens[1] = address(WETH);
        tokens[2] = address(token1);

        uint256 pylon_before;
        uint256 pylon_after;

        pylon_before = token1.balanceOf(address(this));

        if (bountyValueUser > 0) {
            UNIROUTER.swapExactTokensForTokens(bountyValueUser, 0, tokens, address(this), type(uint).max);
        }

        pylon_after = token1.balanceOf(address(this));

        // transfers PYLON tokens to user...don't need to convert here if already done in claimReward()
        // token1.safeTransferFrom(msg.sender, address(this), bountyValueUser); // bountyValueUser has been adjusted and can now be sent to user
        
        // convert bountyValue to WETH and then send to treasury
        // somthing like UNIROUTER.swapExactTokensForTokens(rewardCRVTokenAmountForUsers, 0, tokens1, address(this), type(uint).max);
        // where tokens1 is an array that has CRV and WETH

        address[] memory tokens1 = new address[](2);
        tokens1[0] = address(CRV);
        tokens1[1] = address(WETH);

        if (treasuryBountyValue > 0) {
            UNIROUTER.swapExactTokensForTokens(treasuryBountyValue, 0, tokens1, address(this), type(uint).max);
        }

        uint wethBalance;
        wethBalance = WETH.balanceOf(address(this));
        WETH.transfer(treasury, wethBalance);

        Bounty memory bounty;
        bounty = Bounty(bountyValueUser, block.timestamp, _totalBountyDeposit);
        _bounties.push(bounty); // push bounty struct object to _bounties array
        emit DistributedBounty(msg.sender, bountyValueUser);

        return (pylon_before, pylon_after);

    }

    // here I adapt the original claimReward() logic into two separate functions that also draw upon
    // another function, getBountyValue() to retrieve the max bounty; getBountyValue() is adapated from
    // the modifier in the original contract and code used in the original claimReward() function
    // this function is called on behalf of the user, so pylon token will transfer to PF deployer
    function claimReward() external {
        getReward(msg.sender);

        // uint rewardPylonTokenAmountForUsers = token1.balanceOf(address(this));

        // maxBounty is essentially 'currentRewardAmount' as defined in the original claimReward() function, but is vetted.
        // see getBountyValue() below
        uint256 maxBounty = getBountyValue(msg.sender);
        // is the max reward, not yet differentiated into CRV vs PYLON or with rates applied

        _rewardedBalancePerUser[msg.sender] = _rewardedBalancePerUser[msg.sender].sub(maxBounty); // adjusts the _rewardedBalancePerUser for the claim call
        
        // *** probably need to convert bountyValue into PYLONs here ***
        // *** apply 70%

        // also assess 30% WETH here, send values to distributeBounty (modify this to take 2 args)

        // may not need this check... implementation of this in claimReward() in OG contract is pretty confusing
        // this wouldn't make sense to do if bountyValue is in CRV denomination (an arbitrary value, actually, that
        // simply is implicity denominated in yCRV or yUSD in my logic) hasn't been converted yet
        // but the bountyValue has beem adequately kept track of/updated here so when token1.transfer is called
        // the logic in transfer() function in PYLON.sol properly scales things from CRV values to PYLON
        // uint token1balance = token1.balanceOf(address(this));
        // if (bountyValue > token1balance){
        //     bountyValue = token1balance;
        // } 

        // Transfer converts balance to PYLONS and sends to msg.sender which should be the PF deployer address
        // will use distributeBounty to send to user's address and the share to treasury address

        uint256 finalPylonUserBounty;
        uint256 previousPylonUserBounty;

        (previousPylonUserBounty, finalPylonUserBounty) = _distributeBounty(maxBounty);

        token1.transfer(msg.sender, finalPylonUserBounty);
        emit ClaimedReward(msg.sender, finalPylonUserBounty);
    }


    // this function uses logic from claimReward() in original contract and draws on original modifier method
    // rewardedBalance is equivalent to currentRewardAmount = accTotalReward * accDepositBalancePerUser[msg.sender] / accTotalDeposit in original contract
    function getBountyValue(address userAddress) public view returns (uint256) {

        uint256 rewardedBalance = _rewardedBalancePerUser[userAddress];
        uint256 lastTimestamp = _lastTimestampPerUser[userAddress];

        if (_bounties.length > 0) {
            if (lastTimestamp > 0) {
                for (uint l = _bounties.length - 1; lastTimestamp < _bounties[l].bountyTimeStamp; l--) {
                    rewardedBalance = rewardedBalance.add(_bounties[l].bountyValue.mul(_depositBalancePerUser[userAddress]).div(_bounties[l].totalBountyDeposit));
                    // currentRewardAmount = accTotalReward * accDepositBalancePerUser[msg.sender] / accTotalDeposit;
                    // _bounties[i].amount == accTotalReward in OG
                    // _depositBalances[userAddress] == accDepositBalancePerUser[msg.sender] in OG
                    // _bounties[i].totalDeposit == accTotalDeposit in OG

                    // rewardedBalance becomes maxbounty and is original rewardBalance + currentRewardAmount from OG

                    if (l == 0) break;
                }
            }
        // add option to add time to delay (e.g. force a user to wait a certain amount of time to withdraw or else get penalized?)

        }
        return rewardedBalance;
    }

    function seize(address token, address to) external onlyGov {
        require(IERC20(token) != token0 && IERC20(token) != token1, "main tokens");
        if (token != address(0)) {
            uint256 amount = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(to, amount);
        }
        else {
            uint256 amount = address(this).balance;
            payable(to).transfer(amount);
        }
    }
        
    fallback () external payable { }
    receive () external payable { }
}