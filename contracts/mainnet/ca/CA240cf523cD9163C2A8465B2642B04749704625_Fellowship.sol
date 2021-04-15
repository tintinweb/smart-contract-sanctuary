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
    enum Status {INACTIVE, ACTIVE, PENDING_WITHDRAW, UNFUNDED}

    struct Walker {
        Status status; //status of walker
        uint256 date; //date the walker initally was chosen
        uint256 fellowshipIndex; //index of walker in the fellowship array
        uint256 balance; //TRB balance of walker (must be > stakeAmount to be ACTIVE)
        uint256 rewardBalance; //balance of rewards they own
        string name; //name of walker
    }

    uint256 public lastPayDate; //most recent date walkers were paid
    uint256 public rewardPool; //sum of all payments for services in contract
    uint256 public stakeAmount; //minimum amount each walker needs to stake
    address public rivendell; //the address of the voting contract
    address public tellor; //address of tellor (the token for staking and payments)

    mapping(address => mapping(bytes32 => bytes)) information; //allows parties to store arbitrary information
    mapping(address => Walker) public walkers; //a mapping of an address to their information as a Walker
    mapping(address => uint256) public payments; //a mapping of an address to the payment amount they've given
    //The Fellowship:
    address[] public fellowship; //The array of chosen individuals who are part of the fellowship

    //Events
    event NewWalker(address walker);
    event NewWalkerInformation(address walker, bytes32 input, bytes output);
    event WalkerBanished(address walker);
    event StakeWithdrawalRequestStarted(address walker);
    event StakeWithdrawn(address walker);
    event PaymentDeposited(address payee, uint256 amount);
    event RewardsPaid(uint256 rewardPerWalker);

    //Modifiers
    /**
     * @dev This modifier restricts the function to only the Rivendell contract
     */
    modifier onlyRivendell {
        require(
            msg.sender == rivendell,
            "Only rivendell can call this function."
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
    function banishWalker(address _oldWalker) external onlyRivendell {
        require(
            walkers[_oldWalker].status != Status.INACTIVE,
            "walker is already banished"
        );
        _banishWalker(_oldWalker);
        emit WalkerBanished(_oldWalker);
    }

    /**
     * @dev Function to deposit payment to use Fellowship
     * @param _amount amount of TRB to be used as payment
     **/
    function depositPayment(uint256 _amount) external {
        if (rewardPool > 0) {
            payReward();
        } else {
            lastPayDate = block.timestamp;
        }
        ERC20Interface(tellor).transferFrom(msg.sender, address(this), _amount);
        payments[msg.sender] += _amount;
        rewardPool += _amount;
        emit PaymentDeposited(msg.sender, _amount);
    }

    /**
     * @dev Function to deposit a stake for walkers
     * @param _amount amount of TRB to deposit to account
     **/
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

    /**
     * @dev Change the rivendell (governance) contract
     * @param _newRivendell address to act as owner of the Fellowship
     **/
    function newRivendell(address _newRivendell) external {
        require(
            msg.sender == rivendell || rivendell == address(0),
            "Only rivendell can call this function."
        );
        rivendell = _newRivendell;
    }

    /**
     * @dev Function to add a new walker
     * @param _walker address of walker to be banished (removed from Fellowship)
     * @param _name name of walker
     **/
    function newWalker(address _walker, string memory _name)
        external
        onlyRivendell
    {
        _newWalker(_walker, _name);
    }

    /**
     * @dev function to pay a reward to the walkers
     **/
    function payReward() public {
        uint256 timeSinceLastPayment = block.timestamp - lastPayDate;
        if (timeSinceLastPayment > 6 * 30 days) {
            timeSinceLastPayment = 6 * 30 days;
        }
        uint256 reward =
            (rewardPool * timeSinceLastPayment) /
                6 /
                30 days /
                fellowship.length;
        if (reward > 0) {
            for (uint256 i = 0; i < fellowship.length; i++) {
                if (walkers[fellowship[i]].status == Status.ACTIVE) {
                    walkers[fellowship[i]].rewardBalance += reward;
                    rewardPool -= reward;
                }
            }
            lastPayDate = block.timestamp;
            emit RewardsPaid(reward);
        }
    }

    /**
     * @dev Function lets walkers recieve their reward
     **/
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

    /**
     * @dev Function for walkers to request to withdraw their stake
     **/
    function requestStakingWithdraw() external {
        require(
            walkers[msg.sender].status != Status.INACTIVE,
            "Walker has wrong status"
        );
        walkers[msg.sender].status = Status.PENDING_WITHDRAW;
        walkers[msg.sender].date = block.timestamp;
        emit StakeWithdrawalRequestStarted(msg.sender);
    }

    /**
     * @dev Function for rivendell to change the staking amount
     * @param _amount the staking requirement in TRB
     **/
    function setStakeAmount(uint256 _amount) external onlyRivendell {
        stakeAmount = _amount;
        for (uint256 i = 0; i < fellowship.length; i++) {
            if (walkers[fellowship[i]].status == Status.ACTIVE && walkers[fellowship[i]].balance < stakeAmount) {
                walkers[fellowship[i]].status = Status.UNFUNDED;
            }
        }
    }

    /**
     * @dev Function for walkers to store arbitrary information mapped to their account
     * @param _input the key for the mapping
     * @param _output the result for the mapping
     **/
    function setWalkerInformation(bytes32 _input, bytes memory _output) external {
        require(
            isWalker(msg.sender) || msg.sender == rivendell,
            "must be a valid walker to use this function"
        );
        information[msg.sender][_input] = _output;
        emit NewWalkerInformation(msg.sender, _input, _output);
    }

    /**
     * @dev Function for rivendell to slash a walker
     * @param _walker the address of the slashed walker
     * @param _amount the amount to slash
     * @param _banish a bool to say whether the walker is also banished
     **/
    function slashWalker(
        address _walker,
        uint256 _amount,
        bool _banish
    ) external onlyRivendell {
        if (walkers[_walker].balance >= _amount) {
            walkers[_walker].balance -= _amount;
            rewardPool += _amount;
        } else if (walkers[_walker].balance > 0) {
            rewardPool += walkers[_walker].balance;
            walkers[_walker].balance = 0;
        }
        if (_banish) {
            if (walkers[_walker].status != Status.INACTIVE) {
                _banishWalker(_walker);
            }
        } else if (walkers[_walker].balance < stakeAmount) {
            walkers[_walker].status = Status.UNFUNDED;
        }
    }

    /**
     * @dev Function for walkers to withdraw stake two weeks after requesting a withdrawal
     **/
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

    //View Functions
    /**
     * @dev Function returns the current reward for each walker
     * @return uint256 reward
     **/
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

    /**
     * @dev Function to return the fellowship size
     * @return uint256 size
     **/
    function getFellowshipSize() external view returns (uint256) {
        return fellowship.length;
    }

    /**
     * @dev Function for walkers to withdraw stake two weeks after requesting a withdrawal
     * @param _walker address of the walker of interest
     * @return uint256 epoch timestamp of date walker started
     * @return uint256 index in the fellowship array
     * @return Status of the walker
     * @return uint256 balance of the walker staked
     * @return uint256 balance for withrawal by the walker
     * @return string name of the walker
     **/
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

    /**
     * @dev Function to get arbitrary information set by the walker
     * @param _walker address of walker
     * @param _input mapping key for information mapping
     * @return bytes output of mapping
     **/
    function getWalkerInformation(address _walker, bytes32 _input)
        external
        view
        returns (bytes memory)
    {
        return information[_walker][_input];
    }

    /**
     * @dev Function to check if walker's status is active
     * @param _party address of walker
     * @return bool if walker has Status.ACTIVE
     **/
    function isWalker(address _party) public view returns (bool) {
        if (walkers[_party].status == Status.ACTIVE) {
            return true;
        }
        return false;
    }

    //Internal Functions
    /**
     * @dev Internal function to banish a given walker
     * @param _oldWalker walker to banish
     **/
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

    /**
     * @dev Internal function to add a new walker
     * @param _walker address of new walker
     * @param _name name of new walker
     **/
    function _newWalker(address _walker, string memory _name) internal {
        require(walkers[_walker].date == 0, "cannot already be a walker");
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

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}