/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
       ______                            __             
      / ____/____ _ ____   ____ _ _____ / /_ ___   _____
     / / __ / __ `// __ \ / __ `// ___// __// _ \ / ___/
    / /_/ // /_/ // / / // /_/ /(__  )/ /_ /  __// /    
    \____/ \__,_//_/ /_/ \__, //____/ \__/ \___//_/     
        ______ _        /____/                          
       / ____/(_)____   ____ _ ____   _____ ___         
      / /_   / // __ \ / __ `// __ \ / ___// _ \        
     / __/  / // / / // /_/ // / / // /__ /  __/        
    /_/    /_//_/ /_/ \__,_//_/ /_/ \___/ \___/         
    ==================================================
    | V1.5.0 | Gangster Finance Vault | MIT License |
    =================================================
    
    This contract is for the "Elite Vaults" component of Gangster Finance.
    
=======================================================================================

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
=======================================================================================
*/

/////////////////////////////////////////////////////////////////////////
// SafeMath - prevents a whole class of underflow/overflow math issues //
/////////////////////////////////////////////////////////////////////////

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {return 0;}
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {return 0;} else {return a - b;}
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function max(uint256 a, uint256 b) internal pure returns (uint256) {return a >= b ? a : b;}
    function min(uint256 a, uint256 b) internal pure returns (uint256) {return a < b ? a : b;}
}

/////////////////////////////////////////////////////////////////////////
// Token - A standard BEP20 adapter/interface, enabling token movement //
/////////////////////////////////////////////////////////////////////////

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/////////////////////////////////////////////////////////////////////////
// TokenVault - The smart contract where tokens are stored and handled //
/////////////////////////////////////////////////////////////////////////

contract EliteVaultV1 {
    using SafeMath for uint;

    // Import the token interfaces
    IERC20 token0;
    IERC20 token1;
    
    /////////////////////////////////
    // CONFIGURABLES AND VARIABLES //
    /////////////////////////////////
    
    // Store the developer's wallet address and the token address
    address public developer;
    address public tokenAddress;
    
    bool public activated;
    
    // Store the number of unique users and total Tx's 
    uint public users;
    uint public totalTxs;
    
    uint public startTime; // What time did the vault open?
    uint public lastPayout; // What time was the last payout (timestamp)?
    uint public rewardRate; // What is the multiplier of OGX minting for this vault?
    
    // Store the details of total deposits & claims
    uint public totalClaims;
    uint public totalDeposits;

    // Store the total drip pool balance and rate
    uint  public dripPoolBalance;
    uint8 public dripRate;
    
    // How much GFI must a Gangster hold to get the instant refund
    uint256 public hodlThreshold;

    // 10% fee on deposit and withdrawal
    uint8 constant internal divsFee = 10;
    uint256 constant internal magnitude = 2 ** 64;

    // Rebase and payout frequency
    uint256 constant public rebaseFrequency = 6 hours;
    uint256 constant public payoutFrequency = 2 seconds;
    
    // Timestamp of last rebase
    uint256 public lastRebaseTime;
    
    // Current total tokens staked, and profit per share
    uint256 private currentTotalStaked;
    uint256 private profitPerShare_;
    
    uint256 public firstWhitelistBlock;
    uint256 public secondWhitelistBlock;
    
    uint256 public launchBlock;

    
    ////////////////////////////////////
    // MODIFIERS                      //
    ////////////////////////////////////

    // Only holders - Caller must have funds in the vault
    modifier onlyHolders {
        require(myTokens() > 0);
        _;
    }
    
    // Only earners - Caller must have some earnings
    modifier onlyEarners {
        require(myEarnings() > 0);
        _;
    }
    
    // Only Don - The boss is the boss, y'know?
    modifier onlyDon {
        require(msg.sender == developer, "YOU_ARE_NOT_DON");
        _;
    }

    // Is Enabled - Allows for post-deployment configuration, pre-showtime
    modifier isEnabled {
        require(activated == true || msg.sender == developer, "NOT_READY_YET");
        _;
    }
    
    // Is Not Enabled - Stops any post-showtime buggery with initialization
    modifier isNotEnabled {
        require(activated == false, "ALREADY_STARTED");
        _;
    }
    
    // Checks Whitelists - Multi-staged and controlled by The Don.
    modifier checkWhitelists(address _user) {
        if (_firstWhitelisted[_user] == true) {
            require(block.number > firstWhitelistBlock);
        } else if (_secondWhitelisted[_user] == true) {
            require(block.number > secondWhitelistBlock);
        } else {
            require(block.number > launchBlock);
        }
        _;
    }

    ////////////////////////////////////
    // ACCOUNT STRUCT                 //
    ////////////////////////////////////

    struct Account {
        uint deposited;
        uint withdrawn;
        uint compounded;
        uint rewarded;
        uint contributed;
        uint transferredShares;
        uint receivedShares;
        
        uint xInvested;
        uint xRolled;
        uint xRewarded;
        uint xContributed;
        uint xWithdrawn;
        uint xTransferredShares;
        uint xReceivedShares;
    }

    ////////////////////////////////////
    // MAPPINGS                       //
    ////////////////////////////////////

    mapping(address =>  int256) payoutsTo_;
    mapping(address => uint256) balanceOf_;
    mapping(address => Account) accountOf_;
    
    mapping(address => bool) _firstWhitelisted;
    mapping(address => bool) _secondWhitelisted;
    
    ////////////////////////////////////
    // EVENTS                         //
    ////////////////////////////////////
    
    event onDeposit( address indexed _user, uint256 _deposited,  uint256 tokensRewarded, uint timestamp);
    event onResolve( address indexed _user, uint256 _liquidated, uint256 tokensEarned, uint timestamp);
    event onCompound(address indexed _user, uint256 _compounded, uint256 tokensMinted, uint timestamp);
    event onWithdraw(address indexed _user, uint256 _withdrawn,                        uint timestamp);
    event onTransfer(address indexed from,  address indexed to,  uint256 tokens,       uint timestamp);
    
    event onRebase(uint256 balance, uint256 timestamp);
    event onDonate(address indexed from, uint256 amount, uint timestamp);
    
    event onActivation(uint256 timestamp);
    
    ////////////////////////////////////
    // CONSTRUCTOR                    //
    ////////////////////////////////////

    constructor() public {
        activated = false;
        developer = msg.sender;
    }
    
    ////////////////////////////////////
    // FALLBACK                       //
    ////////////////////////////////////
    
    receive() payable external {
        require(false);
    }
    
    ////////////////////////////////////
    // WRITE FUNCTIONS                //
    ////////////////////////////////////

    // Dividend Sauce, for everyone!
    // This is how you drop tokens directly into the Drip Pool balance
    function donate(uint _amount) isEnabled public returns (uint256) {
        
        // Move the tokens from the caller's wallet to this contract.
        require(token0.transferFrom(msg.sender, address(this), _amount));
        
        // Add the tokens to the drip pool balance
        dripPoolBalance += _amount;
        
        // Tell the network, successful function - how much in the pool now?
        emit onDonate(msg.sender, _amount, block.timestamp);
        return dripPoolBalance;
    }

    // Deposit
    function deposit(uint _amount) isEnabled checkWhitelists(msg.sender) public returns (uint256)  {
        return depositTo(msg.sender, _amount);
    }

    // DepositTo
    function depositTo(address _user, uint _amount) isEnabled public returns (uint256)  {
        
        // Move the tokens from the caller's wallet to this contract.
        require(token0.transferFrom(msg.sender, address(this), _amount));
        
        // Add the deposit to the totalDeposits...
        totalDeposits += _amount;
        
        // Then actually call the deposit method...
        uint amount = _depositTokens(_user, _amount);
        
        // Trigger a distribution for everyone, kind soul!
        distribute();
        
        // Successful function - how many 'shares' (tokens) are the result?
        return amount;
    }

    // Compound
    function compound() onlyEarners isEnabled public {
         _compoundTokens();
    }
    
    // Harvest
    function harvest() onlyEarners isEnabled public {
        address _user = msg.sender;
        uint256 _dividends = myEarnings();
        
        // Calculate the payout, add it to the user's total paid out accounting...
        payoutsTo_[_user] += (int256) (_dividends * magnitude);
        
        // Pay the user their tokens to their wallet
        token0.transfer(_user,_dividends);

        // Update accounting for user/total withdrawal stats...
        accountOf_[_user].withdrawn = SafeMath.add(accountOf_[_user].withdrawn, _dividends);
        accountOf_[_user].xWithdrawn += 1;
        
        // Update total Tx's and claims stats
        totalTxs += 1;
        totalClaims += _dividends;

        // Tell the network...
        emit onWithdraw(_user, _dividends, block.timestamp);

        // Trigger a distribution for everyone, kind soul!
        distribute();
    }

    // Resolve
    function resolve(uint256 _amount) onlyHolders isEnabled public {
        address _user = msg.sender;
        require(_amount <= balanceOf_[_user]);
        
        // Calculate dividends and 'shares' (tokens)
        uint256 _undividedDividends = SafeMath.mul(_amount, divsFee) / 100;
        uint256 _taxedTokens = SafeMath.sub(_amount, _undividedDividends);

        // Subtract amounts from user and totals...
        currentTotalStaked = SafeMath.sub(currentTotalStaked, _amount);
        balanceOf_[_user] = SafeMath.sub(balanceOf_[_user], _amount);

        // Update the payment ratios for the user and everyone else...
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amount + (_taxedTokens * magnitude));
        payoutsTo_[_user] -= _updatedPayouts;

        // Serve dividends between the drip and instant divs (4:1)...
        allocateFees(msg.sender, _undividedDividends);
        
        // Tell the network, and trigger a distribution
        emit onResolve( _user, _amount, _taxedTokens, block.timestamp);
        distribute();
    }

    // Transfer
    function transfer(address _to, uint256 _amount) onlyHolders isEnabled external returns (bool) {
        return _transferTokens(_to, _amount);
    }
    
    //////////////////////////
    // RESTRICTED FUNCTIONS //
    //////////////////////////
    
    // Configure the contract, post-deployment.
    function setupVault(address _tokenAddress, uint8 _dripRate, uint256 _hodlThreshold) onlyDon isNotEnabled public returns (bool _success) {
        tokenAddress = _tokenAddress;
        token0 = IERC20(_tokenAddress);
        
        dripRate = _dripRate;
        
        hodlThreshold = (_hodlThreshold);
        
        startTime = (block.timestamp);
        lastPayout = (block.timestamp);
        
        // Whitelisted access, staggered into threes...
        firstWhitelistBlock = (block.number + 250);
        secondWhitelistBlock = (block.number + 500);
        launchBlock = (block.number + 1000);
        
        activated = true;
        
        emit onActivation(block.timestamp);
        return true;
    }
    
    
    ////////////////////////////////////
    // VIEW FUNCTIONS                 //
    ////////////////////////////////////
    
    // Check if a user is whitelisted, against _list and _user.
    function isWhitelisted(uint8 _list, address _user) public view returns (bool) {
        
        // If we're checking the first round of whitelisted addresses...
        if (_list == 1) {
            
            // ... and if the checked address IS on the first whitelist...
            if (_firstWhitelisted[_user] == true) {
                return true;
            }
            return false;
            
        // Or, if we're checking the second round of whitelisted addresses...
        } else if (_list == 2) {
            
            // ... and if the checked address IS on the second whitelist...
            if (_secondWhitelisted[_user] == true) {
                return true;
            }
            return false;
            
        }
        
        // Otherwise, the address passed in _user is just a normie!
        return false;
    }

    function myTokens() public view returns (uint256) {return balanceOf(msg.sender);}
    function myEarnings() public view returns (uint256) {return dividendsOf(msg.sender);}

    function balanceOf(address _user) public view returns (uint256) {return balanceOf_[_user];}
    function tokenBalance(address _user) public view returns (uint256) {return _user.balance;}
    function totalBalance() public view returns (uint256) {return token0.balanceOf(address(this));}
    function totalSupply() public view returns (uint256) {return currentTotalStaked;}
    
    function dividendsOf(address _user) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * balanceOf_[_user]) - payoutsTo_[_user]) / magnitude;
    }

    function sellPrice() public pure returns (uint256) {
        uint256 _tokens = 1e18;
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tokens, divsFee), 100);
        uint256 _taxedTokens = SafeMath.sub(_tokens, _dividends);
        return _taxedTokens;
    }

    function buyPrice() public pure returns (uint256) {
        uint256 _tokens = 1e18;
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tokens, divsFee), 100);
        uint256 _taxedTokens = SafeMath.add(_tokens, _dividends);
        return _taxedTokens;
    }

    function calculateSharesReceived(uint256 _amount) public pure returns (uint256) {
        uint256 _divies = SafeMath.div(SafeMath.mul(_amount, divsFee), 100);
        uint256 _remains = SafeMath.sub(_amount, _divies);
        uint256 _result = _remains;
        return  _result;
    }

    function calculateTokensReceived(uint256 _amount) public view returns (uint256) {
        require(_amount <= currentTotalStaked);
        uint256 _tokens  = _amount;
        uint256 _divies  = SafeMath.div(SafeMath.mul(_tokens, divsFee), 100);
        uint256 _remains = SafeMath.sub(_tokens, _divies);
        return _remains;
    }

    function accountOf(address _user) public view returns (uint256[14] memory){
        Account memory a = accountOf_[_user];
        uint256[14] memory accountArray = [
            a.deposited, 
            a.withdrawn, 
            a.rewarded, 
            a.compounded,
            a.contributed, 
            a.transferredShares, 
            a.receivedShares, 
            a.xInvested, 
            a.xRewarded, 
            a.xContributed, 
            a.xWithdrawn, 
            a.xTransferredShares, 
            a.xReceivedShares, 
            a.xRolled
        ];
        return accountArray;
    }

    // dailyEstimate: Indeed, an estimate of how many tokens you'll get from the daily drip
    function dailyEstimate(address _user) public view returns (uint256) {
        uint256 share = dripPoolBalance.mul(dripRate).div(100);
        return (currentTotalStaked > 0) ? share.mul(balanceOf_[_user]).div(currentTotalStaked) : 0;
    }

    ////////////////////////////////////
    // PRIVATE / INTERNAL FUNCTIONS   //
    ////////////////////////////////////

    // Allocate fees - Calculates amounts to put into Drip Pool balance and instant divs!
    function allocateFees(address _user, uint fee) private {
        
        // instant = one of ten pieces.
        uint256 onePiece = fee.div(10);
        
        uint256 forDrip;
        uint256 forUser;
        uint256 forDistillery;
        
        uint256 xyzTotal;
        
        uint256 forInstant;
        
        // If user's GFI balance is more than (or equal to) the minimum threshold...
        if (token1.balanceOf(_user) >= hodlThreshold) {
            
            // Drip pool gets 6%, user gets 2% refund, Distillery gets 1% and instant divs = 1%...
            forDrip = onePiece.mul(6);
            forUser = onePiece.mul(2);
            forDistillery = onePiece.mul(1);
            
        // Otherwise...
        } else {
            
            // Drip pool gets 6%, user gets 0% refund, Distillery gets 2% and instant divs = 2%...
            forDrip = onePiece.mul(6);
            forUser = onePiece.mul(0);
            forDistillery = onePiece.mul(2);
        }
        
        // Add the cutaways together...
        xyzTotal = (forDrip.add(forUser).add(forDistillery));
        
        // Subtract cutaways, remainders = instant divs...
        forInstant = onePiece.sub(xyzTotal);

        // If there's more than 0 tokens staked in the vault...
        if (currentTotalStaked > 0) {
            
            // Distribute those instant divs...
            profitPerShare_ = SafeMath.add(profitPerShare_, (onePiece * magnitude) / currentTotalStaked);
        }

        // For Drip = (fee - instant)
        dripPoolBalance += fee.safeSub(forInstant);
    }

    // Distribute - makes the drip, "drip"!
    function distribute() private {
        
        uint _currentTimestamp = (block.timestamp);
        
        // Log a rebase, if it's time to do so...
        if (_currentTimestamp.safeSub(lastRebaseTime) > rebaseFrequency) {
            
            // Tell the network...
            emit onRebase(totalBalance(), _currentTimestamp);
            
            // Update the time this was last updated...
            lastRebaseTime = _currentTimestamp;
        }

        // If there's any time difference...
        if (SafeMath.safeSub(_currentTimestamp, lastPayout) > payoutFrequency && currentTotalStaked > 0) {
            
            // Calculate shares and profits...
            uint256 share = dripPoolBalance.mul(dripRate).div(100).div(24 hours);
            uint256 profit = share * _currentTimestamp.safeSub(lastPayout);
            
            // Subtract from drip pool balance and add to all user earnings
            dripPoolBalance = dripPoolBalance.safeSub(profit);
            profitPerShare_ = SafeMath.add(profitPerShare_, (profit * magnitude) / currentTotalStaked);
            
            // Update the last payout timestamp
            lastPayout = _currentTimestamp;
        }
    }
    
    // _depositTokens - the method which actually does all the accounting on deposit...
    function _depositTokens(address _recipient, uint256 _amount) internal returns (uint256) {
        
        // If the recipient has zero activity, they're new - COUNT THEM!!!
        if (accountOf_[_recipient].deposited == 0 && accountOf_[_recipient].receivedShares == 0) {
            users += 1;
        }

        // Count this tx...
        totalTxs += 1;

        // Calculate dividends and 'shares' (tokens)
        uint256 _undividedDividends = SafeMath.mul(_amount, divsFee) / 100;
        uint256 _tokens = SafeMath.sub(_amount, _undividedDividends);
        
        // Tell the network...
        emit onDeposit(_recipient, _amount, _tokens, block.timestamp);

        // There needs to be something being added in this call...
        require(_tokens > 0 && SafeMath.add(_tokens, currentTotalStaked) > currentTotalStaked);
        if (currentTotalStaked > 0) {
            currentTotalStaked += _tokens;
        } else {
            currentTotalStaked = _tokens;
        }
        
        // Allocate fees, and balance to the recipient
        allocateFees(msg.sender, _undividedDividends);
        balanceOf_[_recipient] = SafeMath.add(balanceOf_[_recipient], _tokens);
        
        // Updated payouts...
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens);
        
        // Update stats...
        payoutsTo_[_recipient] += _updatedPayouts;
        accountOf_[_recipient].deposited += _amount;
        accountOf_[_recipient].xInvested += 1;

        // Successful function - how many "shares" generated?
        return _tokens;
    }
    
    // The internal function which compound() calls
    function _compoundTokens() internal returns (uint256) {
        address _account = msg.sender;
        
        // Quickly roll the caller's earnings into their payouts
        uint256 _dividends = dividendsOf(_account);
        payoutsTo_[_account] += (int256) (_dividends * magnitude);
        
        // Then actually trigger the deposit method
        // (NOTE: No tokens required here, earnings are tokens already within the contract)
        uint256 _tokens = _depositTokens(msg.sender, _dividends);
        
        // Tell the network...
        emit onCompound(_account, _dividends, _tokens, block.timestamp);

        // Then update the stats...
        accountOf_[_account].compounded = SafeMath.add(accountOf_[_account].compounded, _dividends);
        accountOf_[_account].xRolled += 1;
        
        // Call a distribution for everyone, you kind soul!
        distribute();
        
        // Successful function!
        return _tokens;
    }
    
    // Transfer, but don't actually transfer, tokens between users.
    // This means the tokens stay in the contract and keep earning, till the recipient wants to actually withdraw.
    function _transferTokens(address _recipient, uint256 _amount) internal returns (bool _success) {
        address _sender = msg.sender;
        require(_amount <= balanceOf_[_sender]);
        
        // Harvest any earnings before transferring, to help with cleaner accounting
        if (myEarnings() > 0) {
            harvest();
        }
        
        // "Move" the tokens...
        balanceOf_[_sender] = SafeMath.sub(balanceOf_[_sender], _amount);
        balanceOf_[_recipient] = SafeMath.add(balanceOf_[_recipient], _amount);

        // Adjust payout ratios to match the new balances...
        payoutsTo_[_sender] -= (int256) (profitPerShare_ * _amount);
        payoutsTo_[_recipient] += (int256) (profitPerShare_ * _amount);

        // If the recipient has zero activity, they're new - COUNT THEM!!!
        if (accountOf_[_recipient].deposited == 0 && accountOf_[_recipient].receivedShares == 0) {
            users += 1;
        }
        
        // Update stats...
        accountOf_[_sender].xTransferredShares += 1;
        accountOf_[_sender].transferredShares += _amount;
        accountOf_[_recipient].receivedShares += _amount;
        accountOf_[_recipient].xReceivedShares += 1;
        
        // Add this to the Tx counter...
        totalTxs += 1;

        // Tell the network, successful function!
        emit onTransfer(_sender, _recipient, _amount, block.timestamp);
        return true;
    }
}