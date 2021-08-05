pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./safeMath.sol";


contract Tool {
    using SafeMath for uint256;

    MyToken ticketAddress;

    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier isOwn() {
        require(msg.sender == owner);
        _;
    }

    function init(address _ticketAddress) public isOwn {
        ticketAddress = MyToken(_ticketAddress);
    }

    function _getNeedTicketNum(uint256 _balance) public view returns (uint256) {
        uint256 _needTicketUSDT = _balance.div(1e6).div(10);

        uint256 _ticketPrice = ticketAddress.getTokenPrice();
        uint256 _needTicket = _needTicketUSDT.mul(_ticketPrice);
        return _needTicket;
    }

    function _getRatio(uint256 _balance) public pure returns (uint256) {
        require(_balance >= 100e6, "amount <= 100e6");
        require(_balance.mod(1e6) == 0, "amount != e6");

        uint256 _num = _balance.div(1e6);

        if (_num < 3000) {
            return uint256(3);
        } else if (_num < 7000) {
            return uint256(4);
        } else {
            return uint256(5);
        }
    }

    function _createRandomNum(
        uint256 _min,
        uint256 _max,
        uint256 _randNonce
    ) public view returns (uint256) {
        uint256 _random = uint256(
            keccak256(abi.encode(now, tx.origin, _randNonce))
        )
            .mod(_max.sub(_min));

        return _random.add(_min);
    }

    function _crateLuckCodeList(uint256 _max)
        public
        view
        returns (uint256[25] memory)
    {
        uint256[25] memory _random;
        for (uint256 i = 0; i < 25; i++) {
            _random[i] = _createRandomNum(1, _max, i.add(now));
        }
        return _random;
    }
}


abstract contract MyToken {
    function getToken(address _own) public virtual returns (uint256);

    function sendTokenToGame(address _to, uint256 _value)
        public
        virtual
        returns (bool);

    function getTokenPrice() public virtual view returns (uint256);

    function price() public virtual view returns (uint256);
}
