// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./interfaces/ERC20Interface.sol";

/****

████████╗██╗░░██╗███████╗  ███████╗███████╗██╗░░░░░██╗░░░░░░█████╗░░██╗░░░░░░░██╗░██████╗██╗░░██╗██╗██████╗░
╚══██╔══╝██║░░██║██╔════╝  ██╔════╝██╔════╝██║░░░░░██║░░░░░██╔══██╗░██║░░██╗░░██║██╔════╝██║░░██║██║██╔══██╗
░░░██║░░░███████║█████╗░░  █████╗░░█████╗░░██║░░░░░██║░░░░░██║░░██║░╚██╗████╗██╔╝╚█████╗░███████║██║██████╔╝
░░░██║░░░██╔══██║██╔══╝░░  ██╔══╝░░██╔══╝░░██║░░░░░██║░░░░░██║░░██║░░████╔═████║░░╚═══██╗██╔══██║██║██╔═══╝░
░░░██║░░░██║░░██║███████╗  ██║░░░░░███████╗███████╗███████╗╚█████╔╝░░╚██╔╝░╚██╔╝░██████╔╝██║░░██║██║██║░░░░░
░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═╝░░░░░╚══════╝╚══════╝╚══════╝░╚════╝░░░░╚═╝░░░╚═╝░░╚═════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░

*****/

/** 
 @author Tellor Inc.
 @title Fellowship
 @dev This contract holds the selected few chosen as part of the Fellowship
**/
contract Fellowship {
    //Storage
    enum Status {ACTIVE, INACTIVE, PENDING_WITHDRAW, UNFUNDED}

    struct Walker {
        Status status; //status of walker
        uint256 date; //date the walker initally was chosen
        uint256 fellowshipIndex; //index of walker in the fellowship array
        uint256 balance; //TRB balance of walker (must be > stakeAmount to be ACTIVE)
        uint256 rewardBalance; //balance of rewards they own
        string name; //name of walker
    }

    uint256 public lastPayDate; //most recent date walkers were paid
    uint256 public lastPayDate2; //most recent date walkers were paid
    uint256 public rewardPool; //sum of all payments for services in contract
    uint256 public stakeAmount; //minimum amount each walker needs to stake
    address public rivendale; //the address of the voting contract
    address public tellor; //address of tellor (the token for staking and payments)

    mapping(address => mapping(bytes32 => bytes)) information; //allows parties to store arbitrary information
    mapping(address => Walker) public walkers; //a mapping of an address to their information as a Walker
    mapping(address => uint256) public payments; //a mapping of an address to the payment amount they've given
    //The Fellowship:
    address[] public fellowship; //The array of chosen individuals who are part of the fellowship

    //Events
    event NewWalker2(address walker);
    event NewWalker(address walker);
    event NewWalkerInformation(address walker, bytes32 input, bytes output);
    event WalkerBanished(address walker);
    event StakeWithdrawalRequestStarted(address walker);
    event StakeWithdrawn(address walker);
    event PaymentDeposited(address payee, uint256 amount);
    event RewardsPaid(uint256 rewardPerWalker);

    //Modifiers
    /**
     * @dev This modifier restricts the function to only the Rivendale contract
     */
    modifier onlyRivendale {
        require(
            msg.sender == rivendale,
            "Only rivendale can call this function."
        );
        _;
    }

    //Functions
    /**
     * @dev Constructor for setting initial variables
     * @param _tellor the address of the tellor contract
     * @param _initialWalkers an array of three addresses to serve as the initial walkers
     */
    constructor(address _tellor, address[3] memory _initialWalkers) {
        tellor = _tellor;
        _newWalker(_initialWalkers[0], "Aragorn");
        _newWalker(_initialWalkers[1], "Legolas");
        _newWalker(_initialWalkers[2], "Gimli");
        stakeAmount = 10 ether;
    }

    /**
     * @dev Function to banish a walker
     * @param _oldWalker address of walker to be banished (removed from Fellowship)
     **/
    function banishWalker(address _oldWalker) external onlyRivendale {
        _banishWalker(_oldWalker);
        emit WalkerBanished(_oldWalker);
    }

    function depositPayment(uint256 _amount) external {
        payReward();

        ERC20Interface(tellor).transferFrom(msg.sender, address(this), _amount);
        payments[msg.sender] += _amount;
        rewardPool += _amount;
        emit PaymentDeposited(msg.sender, _amount);
    }

    function depositStake(uint256 _amount) external {
        ERC20Interface(tellor).transferFrom(msg.sender, address(this), _amount);
        walkers[msg.sender].balance += _amount;
        require(
            walkers[msg.sender].status != Status.INACTIVE,
            "Walker has wrong status"
        );
        require(
            walkers[msg.sender].status != Status.PENDING_WITHDRAW,
            "Walker has wrong status"
        );
        if (walkers[msg.sender].balance >= stakeAmount) {
            walkers[msg.sender].status = Status.ACTIVE;
        }
    }

    function newRivendale(address _newRivendale) external {
        require(
            msg.sender == rivendale || rivendale == address(0),
            "Only rivendale can call this function."
        );
        rivendale = _newRivendale;
    }

    function newWalker(address _walker, string memory _name)
        external
        onlyRivendale
    {
        require(walkers[_walker].date == 0, "cannot already be a walker");
        _newWalker(_walker, _name);
    }

    function payReward() public {
        lastPayDate = block.timestamp;

        if (rewardPool > 0) {
            uint256 timeSinceLastPayment = block.timestamp - lastPayDate;
            if (timeSinceLastPayment > 6 * 30 days) {
                timeSinceLastPayment = 6 * 30 days;
            }
            uint256 reward =
                (rewardPool * timeSinceLastPayment) /
                    6 /
                    30 days /
                    fellowship.length;
            for (uint256 i = 0; i < fellowship.length; i++) {
                if (walkers[fellowship[i]].status == Status.ACTIVE) {
                    walkers[fellowship[i]].rewardBalance += reward;
                    rewardPool -= reward;
                }
            }
            emit RewardsPaid(reward);
        }
    }

    //to pay out the reward
    function recieveReward() external {
        require(
            walkers[msg.sender].status == Status.ACTIVE,
            "Walker has wrong status"
        );
        ERC20Interface(tellor).transfer(
            msg.sender,
            walkers[msg.sender].rewardBalance
        );
        walkers[msg.sender].rewardBalance = 0;
    }

    function requestStakingWithdraw() external {
        require(
            walkers[msg.sender].status != Status.INACTIVE,
            "Walker has wrong status"
        );
        walkers[msg.sender].status = Status.PENDING_WITHDRAW;
        walkers[msg.sender].date = block.timestamp;
        emit StakeWithdrawalRequestStarted(msg.sender);
    }

    function setStakeAmount(uint256 _amount) external onlyRivendale {
        stakeAmount = _amount;
        for (uint256 i = 0; i < fellowship.length; i++) {
            if (walkers[fellowship[i]].balance < stakeAmount) {
                walkers[fellowship[i]].status = Status.UNFUNDED;
            }
        }
    }

    //a function to store input about keys on other chains or other necessary details;
    function setWalkerInformation(bytes32 _input, bytes memory _output)
        external
    {
        information[msg.sender][_input] = _output;
        emit NewWalkerInformation(msg.sender, _input, _output);
    }

    function slashWalker(
        address _walker,
        uint256 _amount,
        bool _banish
    ) external onlyRivendale {
        walkers[_walker].balance -= _amount;
        rewardPool += _amount;
        if (_banish) {
            _banishWalker(_walker);
        } else if (walkers[_walker].balance < stakeAmount) {
            walkers[_walker].status = Status.UNFUNDED;
        }
    }

    function withdrawStake() external {
        require(
            walkers[msg.sender].status == Status.PENDING_WITHDRAW,
            "walker has wrong status"
        );
        require(
            block.timestamp - walkers[msg.sender].date > 14 days,
            "has not been long enough to withdraw"
        );
        ERC20Interface(tellor).transfer(
            msg.sender,
            walkers[msg.sender].balance
        );
        walkers[msg.sender].balance = 0;
        _banishWalker(msg.sender);
        emit StakeWithdrawn(msg.sender);
    }

    //view functions

    function checkReward() external view returns (uint256) {
        uint256 timeSinceLastPayment = block.timestamp - lastPayDate;
        if (timeSinceLastPayment > 6 * 30 days) {
            timeSinceLastPayment = 6 * 30 days;
        }
        return ((rewardPool * timeSinceLastPayment) /
            6 /
            30 days /
            fellowship.length);
    }

    function getFellowshipSize() external view returns (uint256) {
        return fellowship.length;
    }

    function getWalkerDetails(address _walker)
        external
        view
        returns (
            uint256,
            uint256,
            Status,
            uint256,
            uint256,
            string memory
        )
    {
        return (
            walkers[_walker].date,
            walkers[_walker].fellowshipIndex,
            walkers[_walker].status,
            walkers[_walker].balance,
            walkers[_walker].rewardBalance,
            walkers[_walker].name
        );
    }

    function getWalkerInformation(address _walker, bytes32 _input)
        external
        view
        returns (bytes memory _output)
    {
        return information[_walker][_input];
    }

    //checks whether they are a Walker
    function isWalker(address _a) external view returns (bool _i) {
        if (walkers[_a].status == Status.ACTIVE) {
            return true;
        }
        return false;
    }

    function _banishWalker(address _oldWalker) internal {
        fellowship[walkers[_oldWalker].fellowshipIndex] = fellowship[
            fellowship.length - 1
        ];
        walkers[fellowship[fellowship.length - 1]].fellowshipIndex = walkers[
            _oldWalker
        ]
            .fellowshipIndex;
        fellowship.pop();
        walkers[_oldWalker].fellowshipIndex = 0;
        walkers[_oldWalker].status = Status.INACTIVE;
        ERC20Interface(tellor).transfer(
            _oldWalker,
            walkers[_oldWalker].balance
        );
        walkers[_oldWalker].balance = 0;
        rewardPool += walkers[_oldWalker].rewardBalance;
        walkers[_oldWalker].rewardBalance = 0;
    }

    function _newWalker(address _walker, string memory _name) internal {
        fellowship.push(_walker);
        walkers[_walker] = Walker({
            date: block.timestamp,
            name: _name,
            status: Status.UNFUNDED,
            fellowshipIndex: fellowship.length - 1,
            balance: 0,
            rewardBalance: 0
        });
        emit NewWalker(_walker);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20Interface {
    function transfer(address _to, uint256 _amount) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function balanceOf(address _addy) external returns (uint256);

    function balanceOfAt(address _addy, uint256 _block)
        external
        returns (uint256);
}

