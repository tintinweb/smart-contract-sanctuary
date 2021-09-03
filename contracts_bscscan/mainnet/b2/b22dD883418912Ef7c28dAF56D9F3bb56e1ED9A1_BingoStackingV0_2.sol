// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | |  ___  ____   | || |     ____     | || |      __      | || |   _____      | || |      __      | |
// | | |_  ||_  _|  | || |   .'    `.   | || |     /  \     | || |  |_   _|     | || |     /  \     | |
// | |   | |_/ /    | || |  /  .--.  \  | || |    / /\ \    | || |    | |       | || |    / /\ \    | |
// | |   |  __'.    | || |  | |    | |  | || |   / ____ \   | || |    | |   _   | || |   / ____ \   | |
// | |  _| |  \ \_  | || |  \  `--'  /  | || | _/ /    \ \_ | || |   _| |__/ |  | || | _/ /    \ \_ | |
// | | |____||____| | || |   `.____.'   | || ||____|  |____|| || |  |________|  | || ||____|  |____|| |
// | |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
// '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

/*

// For next versions
// TODO 
// reset users amount value when withdraw prizes
// a way to update participation price (add first a clean up of deposit amount)
// record real deposit amount is case of tokens with transfer tax (preparation for NALIS token)
// TEST / record number of participant without maths

*/


import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract BingoStackingV0_2 is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint16 depositFeeBP;      // V1 Deposit fee in basis points
    }

    // The LYPTUS TOKEN!
    IBEP20 public lyptus;

    // LYPTUS bingo card price
    uint256 public lyptusPerCard;
    
    // Deposit burn address
    address public burnAddress;
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD; 
    // Deposit fee to burn
    uint16 public depositFeeToBurn;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // The block number when Bingo starts.
    uint256 public startBlock;
    // The block number when Bingo ends.
    uint256 public endBlock;
    // Number of participants
    uint256 public nbrParticipant;    

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _lyptus,
        uint256 _lyptusPerCard,
        uint16 _depositFeeBP, // V1
        uint256 _startBlock,
        uint256 _endBlock
    ) public {
        lyptus = _lyptus;
        lyptusPerCard = _lyptusPerCard;
        burnAddress = BURN_ADDRESS;
        depositFeeToBurn = _depositFeeBP;
        startBlock = _startBlock;
        endBlock = _endBlock;

        // Deposit fee limited to 50% No way for contract owner to set higher deposit fee
        require(depositFeeToBurn <= 5000, "contract: invalid deposit fee basis points");

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _lyptus,
            depositFeeBP: depositFeeToBurn
        }));

    }

    function forceEndBlock() public onlyOwner {
        endBlock = block.number;
    }

    // Stake LYPTUS tokens to BingoStacking
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        require(block.number >= startBlock, 'no stacking possible before startblock passed');
        require(block.number <= endBlock, 'no stacking possible after endblock passed');
        require(user.amount == 0, "contract: user already stacked in");
        require(_amount == lyptusPerCard, "contract: invalid deposit amount");
 
        // Deposit fees sent to burn address
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(burnAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
            // add one participant to the counter
            nbrParticipant = nbrParticipant.add(10);
        }        
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw tokens. Dev can withdraw the stacked tokens to distribute them to the Bingo winners
    function tokenWithdraw(uint256 _amount) public onlyOwner {
        PoolInfo storage pool = poolInfo[0];

        require(block.number > endBlock, 'no withdraw possible until endblock passed');
        require(_amount <= pool.lpToken.balanceOf(address(this)), 'not enough token');
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
    }
 
    // Add a function to update bonusEndBlock. Can only be called by the owner.
    function updateBonusEndBlock(uint256 _endBlock) public onlyOwner {
        endBlock = _endBlock;
    }   
    
    // Update lyptusPerCard. Can only be called by the owner.
    function updateLyptusPerCard(uint256 _lyptusPerCard) public onlyOwner {
        lyptusPerCard = _lyptusPerCard;
    }     
    
    // Update the given pool's deposit fee. Can only be called by the owner.
    function updateDepositFeeBP(uint256 _pid, uint16 _depositFeeBP) public onlyOwner {
        require(_depositFeeBP <= 50000, "updateDepositFeeBP: invalid deposit fee basis points");
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        depositFeeToBurn = _depositFeeBP;
    }
    
    // View function to see user minimum deposit on frontend.
    function checkDeposit(address _user) external view returns (bool) {
        UserInfo storage user = userInfo[_user];

        if(user.amount > 0) {
            return true;
        }
        else {
            return false;
        }
    }    

    // V0_1 : Update : nbrParticipant is now a simple counter
    // View function to see participant number on frontend.
    // frontend need to divide return value by 10 and round it to the upper number
    function getNumberOfParticipant() external view returns (uint256) {
        return nbrParticipant;
    }
    
    // View function to get total deposit on frontend.
    // avoid 2 ABI calls from the frontend
    function getTotalDeposit() external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
 
        return lpSupply;
    }    

}