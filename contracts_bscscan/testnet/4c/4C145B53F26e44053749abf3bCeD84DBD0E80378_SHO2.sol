// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import './StakingB.sol';

contract SHO2 {
    address public owner;
    Staking public STK;
    IERC20 public BUSD;
    IERC20 public SFP;

    uint32 public REGISTRATION_DATE = 1626004800;
    uint32 public REST_DATE = 1626091200;
    uint32 public DRAW_DATE = 1626109200;
    uint32 public FILLED_DATE = 1626714000;
    bool public DRAW_DONE = false;
    uint256 public constant PLACES = 1000;
    uint256 public constant BUSD_AMOUNT = 250e18;
    uint256 public constant SFP_AMOUNT = 714285e15;
    uint256 public constant TOTAL_BUSD_AMOUNT = 250000e18;
    uint256 public constant TOTAL_SFP_AMOUNT = 714285e18;
    uint256 public CLAIMED;
    uint256 public constant STAKED_PER_TICKET = 100e18;

    address[] public participants;
    address[] public list;
    mapping(address => bool) public hasRegistered;
    mapping(address => bool) public hasClaimed;
    mapping(address => bool) public isWinner;
    mapping(address => uint256) public ticketCount;

    modifier restricted {
        require(msg.sender == owner, 'This function is restricted to owner');
        _;
    }

    function register(uint256 _stake) public {
        require(msg.sender == STK.ownerOf(_stake), 'this is not your stake');
        require(block.timestamp >= REGISTRATION_DATE, 'registration not open yet');
        require(block.timestamp < REST_DATE, 'registration is closed already');
        require(!hasRegistered[msg.sender], 'you have already registered');
        (uint8 _class, , , uint256 _amount, uint256 _timestamp, ) = STK.stakes(_stake);
        require(uint32(_timestamp) + STK.periods(_class) > DRAW_DATE, 'your stake finishes before draw date');
        BUSD.transferFrom(msg.sender, address(this), BUSD_AMOUNT);
        participants.push(msg.sender);
        uint256 _tickets = ((_amount * 100) / STK.rates(_class)) / STAKED_PER_TICKET;
        for (uint256 i = 0; i < _tickets; i++) list.push(msg.sender);
        hasRegistered[msg.sender] = true;
        ticketCount[msg.sender] = _tickets;
    }

    function draw() public restricted {
        require(block.timestamp >= DRAW_DATE, 'draw not allowed yet');
        require(!DRAW_DONE, 'draw already done');
        if (participants.length <= PLACES) for (uint256 i = 0; i < participants.length; i++) isWinner[participants[i]] = true;
        else {
            address[] memory _list = list;
            uint256 _ll = list.length;
            for (uint256 i = 0; i < PLACES; i++) {
                address _winner = _list[_generateRandom(_ll, i)];
                isWinner[_winner] = true;
                uint _t = ticketCount[_winner];
                for (uint256 j = _ll; j > 0 && _t > 0; j--)
                    if (_list[j-1] == _winner) {
                        _list[j-1] = _list[_ll - 1];
                        _ll--;
                        _t--;
                    }
            }
        }
        DRAW_DONE = true;
    }

    function _generateRandom(uint256 range, uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, salt))) % range;
    }

    function claim() public {
        require(DRAW_DONE, 'draw not done yet');
        require(hasRegistered[msg.sender], 'you were not participating');
        require(!hasClaimed[msg.sender], 'you have claimed already');
        require(block.timestamp < FILLED_DATE, 'too late');
        if (isWinner[msg.sender]) {
            require(CLAIMED + SFP_AMOUNT <= TOTAL_SFP_AMOUNT, 'whole reserve has already been claimed');
            SFP.transfer(msg.sender, SFP_AMOUNT);
            CLAIMED += SFP_AMOUNT;
        } else {
            BUSD.transfer(msg.sender, BUSD_AMOUNT);
        }
        hasClaimed[msg.sender] = true;
    }

    function take(IERC20 _TKN, uint256 _amount) public restricted {
        require(block.timestamp >= FILLED_DATE, '1 week must pass since the draw');
        _TKN.transfer(msg.sender, _amount > 0 ? _amount : _TKN.balanceOf(address(this)));
    }

    function getParticipantsList()
        public
        view
        returns (
            address[] memory user,
            bool[] memory won,
            bool[] memory claimed
        )
    {
        user = participants;
        won = new bool[](participants.length);
        claimed = new bool[](participants.length);
        for (uint256 i = 0; i < participants.length; i++) {
            won[i] = isWinner[participants[i]];
            claimed[i] = hasClaimed[participants[i]];
        }
    }

    function infoBundle(address _user)
        public
        view
        returns (
            uint256 claimed,
            bool draw_done,
            uint256 busd,
            uint256 sfp,
            bool uRegistered,
            bool uWinner,
            bool uClaimed,
            uint256 tickets
        )
    {
        claimed = CLAIMED;
        draw_done = DRAW_DONE;
        busd = BUSD.balanceOf(_user);
        sfp = SFP.balanceOf(_user);
        uRegistered = hasRegistered[_user];
        uWinner = isWinner[_user];
        uClaimed = hasClaimed[_user];
        tickets = ticketCount[_user];
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), 'Invalid address: should not be 0x0');
        owner = _newOwner;
    }

    function resetState(uint32 registrationLength, uint32 restLength, uint32 drawLength) public restricted {
        for (uint256 i = 0; i < participants.length; i++) {
            hasRegistered[participants[i]] = false;
            hasClaimed[participants[i]] = false;
            isWinner[participants[i]] = false;
            delete ticketCount[participants[i]];
        }
        delete participants;
        delete list;
        DRAW_DONE = false;
        CLAIMED = 0;
        REGISTRATION_DATE = uint32(block.timestamp);
        REST_DATE = REGISTRATION_DATE + (registrationLength * 60);
        DRAW_DATE = REST_DATE + (restLength * 60);
        FILLED_DATE = DRAW_DATE + (drawLength * 60);
    }

    constructor(
        Staking _STK,
        IERC20 _BUSD,
        IERC20 _SFP
    ) {
        owner = msg.sender;
        STK = _STK;
        BUSD = _BUSD;
        SFP = _SFP;
    }
}