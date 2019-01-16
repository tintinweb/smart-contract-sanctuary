pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/* solhint-disable max-line-length */
contract HoprChannel {
    using SafeMath for uint256;
    // using ECDSA for bytes32;
    
    // constant RELAY_FEE = 1
    uint8 constant private BLOCK_CONFIRMATION = 15;
    
    // Tell payment channel partners that the channel has been settled
    event SettledChannel(bytes32 indexed channelId, uint256 index, uint256 amountA) anonymous;

    // Tell payment channel partners that the channel has been opened
    event OpenedChannel(bytes32 channelId, uint256 amount);

    // Track the state of the channels
    enum ChannelState {
        UNINITIALIZED, // 0
        PARTYA_FUNDED, // 1
        PARTYB_FUNDED, // 2
        ACTIVE, // 3
        PENDING_SETTLEMENT, // 4
        WITHDRAWN // 5
    }

    struct Channel {
        ChannelState state;
        uint256 balance;
        uint256 balanceA;
        uint256 index;
        uint256 settlementBlock;
    }

    // Open channels
    mapping(bytes32 => Channel) public channels;
    
    struct State {
        bool isSet;
        // number of open channels
        // Note: the smart contract doesn&#39;t know the actual
        //       channels but it knows how many open ones
        //       there are.
        uint256 openChannels;
        uint256 stakedEther;
        int32 counter;
    }

    // Keeps track of the states of the
    // participating parties.
    mapping(address => State) public states;

    modifier enoughFunds(uint256 amount) {
        require(amount <= states[msg.sender].stakedEther, "Insufficient funds.");
        _;
    }

    modifier channelExists(address counterParty) {
        bytes32 channelId = getId(counterParty);
        Channel memory channel = channels[channelId];
        
        require(channel.state > ChannelState.UNINITIALIZED && channel.state < ChannelState.WITHDRAWN, "Channel does not exist.");
        _;
    }

    /**
    * @notice desposit ether to stake
    */
    function stakeEther() public payable {
        require(msg.value > 0, "Please provide a non-zero amount of ether.");
        
        states[msg.sender].isSet = true;
        states[msg.sender].stakedEther = states[msg.sender].stakedEther.add(uint256(msg.value));
    }
    
    /**
    * @notice withdrawal staked ether
    * @param amount uint256
    */
    function unstakeEther(uint256 amount) public enoughFunds(amount) {
        require(states[msg.sender].openChannels == 0, "Waiting for remaining channels to close.");
        
        if (amount == states[msg.sender].stakedEther) {
            delete states[msg.sender];
        } else {
            states[msg.sender].stakedEther = states[msg.sender].stakedEther.sub(amount);
        }

        msg.sender.transfer(amount);
    }

    function getStakedAmount(address _address) public view returns (uint256) {
        return states[_address].stakedEther;
    }
    
    /**
    * @notice create payment channel TODO: finish desc
    * @param counterParty address of the counter party
    * @param amount uint256
    */
    function create(address counterParty, uint256 amount) public enoughFunds(amount) {
        require(channels[getId(counterParty)].state == ChannelState.UNINITIALIZED, "Channel already exists.");
        
        states[msg.sender].stakedEther = states[msg.sender].stakedEther.sub(amount);
        
        // Register the channels at both participants&#39; state
        states[msg.sender].openChannels = states[msg.sender].openChannels.add(1);
        states[counterParty].openChannels = states[counterParty].openChannels.add(1);
        
        if (isPartyA(counterParty)) {
            // msg.sender == partyB
            channels[getId(counterParty)] = Channel(ChannelState.PARTYB_FUNDED, amount, 0, 0, 0);
        } else {
            // msg.sender == partyA
            channels[getId(counterParty)] = Channel(ChannelState.PARTYA_FUNDED, amount, amount, 0, 0);
        }
    }
    
    /**
    * @notice fund payment channel TODO: finish desc
    * @param counterParty address of the counter party
    * @param amount uint256
    */
    function fund(address counterParty, uint256 amount) public enoughFunds(amount) channelExists(counterParty) {
        states[msg.sender].stakedEther = states[msg.sender].stakedEther.sub(amount);

        Channel storage channel = channels[getId(counterParty)];

        if (isPartyA(counterParty)) {
            // msg.sender == partyB
            require(channel.state == ChannelState.PARTYA_FUNDED, "Channel already exists.");
            
            channel.balance = channel.balance.add(amount);
        } else {
            // msg.sender == partyA
            require(channel.state == ChannelState.PARTYB_FUNDED, "Channel already exists.");
            
            channel.balance = channel.balance.add(amount);
            channel.balanceA = channel.balanceA.add(amount);
        }
        channel.state = ChannelState.ACTIVE;
    }
    
    /**
    * @notice pre-fund channel by with staked Ether of both parties
    * @param counterParty address of the counter party
    * @param amount uint256 how much money both parties put into the channel
    * @param r bytes32 signature first part
    * @param s bytes32 signature second part
    * @param v uint8 version
     */
    function createFunded(address counterParty, uint256 amount, bytes32 r, bytes32 s, bytes1 v) public enoughFunds(amount) {
        require(channels[getId(counterParty)].state == ChannelState.UNINITIALIZED, "Channel already exists.");

        require(states[counterParty].stakedEther >= amount, "Insufficient funds");

        bytes32 hashedMessage = keccak256(abi.encodePacked(amount, uint256(1), getId(counterParty)));

        require(ecrecover(hashedMessage, uint8(v) + 27, r, s) == counterParty, "Invalid opening transaction");

        states[msg.sender].stakedEther = states[msg.sender].stakedEther - amount;
        states[counterParty].stakedEther = states[counterParty].stakedEther - amount;

        states[msg.sender].openChannels = states[msg.sender].openChannels + 1;
        states[counterParty].openChannels = states[counterParty].openChannels + 1;
        
        channels[getId(counterParty)] = Channel(ChannelState.ACTIVE, 2 * amount, amount, 0, 0);        
    }

    /**
    * @notice settle payment channel TODO: finish desc
    * @param counterParty address of the counter party
    * @param index uint256
    * @param balanceA uint256
    * @param r bytes32
    * @param s bytes32
    */
    function settle(address counterParty, uint256 index, uint256 balanceA, bytes32 r, bytes32 s, bytes1 v) public channelExists(counterParty) {
        bytes32 channelId = getId(counterParty);
        Channel storage channel = channels[channelId];
        
        require(
            channel.index < index &&
            channel.state == ChannelState.ACTIVE || channel.state == ChannelState.PENDING_SETTLEMENT,
            "Invalid channel.");
               
        // is the proof valid?
        bytes32 hashedMessage = keccak256(abi.encodePacked(balanceA, index, channelId));
        require(ecrecover(hashedMessage, uint8(v) + 27, r, s) == counterParty, "Invalid signature.");
        
        channel.balanceA = balanceA;
        channel.index = index;
        channel.state = ChannelState.PENDING_SETTLEMENT;
        channel.settlementBlock = block.number.add(BLOCK_CONFIRMATION);
        
        emit SettledChannel(channelId, index, balanceA);
    }
    
    /**
    * @notice TODO: finish desc
    * @param counterParty address of the counter party
    */
    function withdraw(address counterParty) public channelExists(counterParty) {
        Channel storage channel = channels[getId(counterParty)];
        
        require(
            channel.state == ChannelState.PENDING_SETTLEMENT && 
            channel.balanceA <= channel.balance, 
            "Invalid channel.");

        require(channel.settlementBlock <= block.number, "Channel not withdrawable yet.");
        
        channel.state = ChannelState.WITHDRAWN;
        
        require(
            states[msg.sender].openChannels > 0 &&
            states[counterParty].openChannels > 0, 
            "Something went wrong. Double spend?");

        states[msg.sender].openChannels = states[msg.sender].openChannels.sub(1);
        states[counterParty].openChannels = states[counterParty].openChannels.sub(1);
        
        if (isPartyA(counterParty)) {
            // msg.sender == partyB
            states[msg.sender].stakedEther = states[msg.sender].stakedEther.add((channel.balance.sub(channel.balanceA)));
            states[counterParty].stakedEther = states[counterParty].stakedEther.add(channel.balanceA);
        } else {
            // msg.sender == partyA
            states[counterParty].stakedEther = states[counterParty].stakedEther.add((channel.balance.sub(channel.balanceA)));
            states[msg.sender].stakedEther = states[msg.sender].stakedEther.add(channel.balanceA); 
        }

        delete channels[getId(counterParty)];
    }

    /*** PRIVATE | INTERNAL ***/
    /**
    * @notice compares addresses `msg.sender` vs `counterParty` 
    * @param counterParty address of the counter party
    * @return bool 
    */
    function isPartyA(address counterParty) private view returns (bool) {
        require(msg.sender != counterParty, "Cannot open channel between one party.");

        return bytes20(msg.sender) < bytes20(counterParty);
    }

    /**
    * @notice returns keccak256 hash of `counterParty` & `msg.sender` which is used as an id
    * @dev order of arguements pending result of `isPartyA(counterParty)`
    * @param counterParty address of the counter party
    * @return bytes32 
    */
    function getId(address counterParty) private view returns (bytes32) {
        if (isPartyA(counterParty)) {
            return keccak256(abi.encodePacked(msg.sender, counterParty));
        } else {
            return keccak256(abi.encodePacked(counterParty, msg.sender));
        }
    }
}