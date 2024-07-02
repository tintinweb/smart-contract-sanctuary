// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

import "./RecordInterface.sol";
import "./UserStorage.sol";

contract AppealStorage {
    OrderInterface private _oSt;
    RecordInterface private _rSt;
    UserInterface private _uSt;
    address recAddr;

    struct Appeal {
        address user;
        uint256 appealNo;
        uint256 orderNo;
        address witness;
        address buyer;
        address seller;
        uint256 mortgage;
        uint256 status;
        uint256 appealTime;
        uint256 witTakeTime;
        uint256 obTakeTime;
        AppealDetail detail;
    }

    struct AppealDetail {
        address finalAppealAddr;
        uint256 updateTime;
        string witnessReason;
        uint256 witnessAppealStatus;
        string observerReason;
        uint256 witnessHandleTime;
        uint256 observerHandleTime;
        address observerAddr;
        uint256 witnessHandleReward;
        uint256 observerHandleReward;
        uint256 witnessHandleCredit;
        uint256 observerHandleCredit;
        uint256 witReward;
        uint256 witSub;
        uint256 witCreditR;
        uint256 witCreditS;
    }

    mapping(uint256 => Appeal) public appeals;
    mapping(uint256 => uint256) public appealIndex;

    Appeal[] public appealList;

    event addAppeal(uint256 _appealNo, uint256 _orderNo);

    constructor(
        address _r,
        address _o,
        address _u
    ) {
        _rSt = RecordInterface(_r);
        _oSt = OrderInterface(_o);
        _uSt = UserInterface(_u);
        recAddr = _r;
    }

    modifier onlyWit(uint256 _o) {
        Appeal memory _al = appeals[_o];
        require(_al.witness == msg.sender);
        require(_al.buyer != msg.sender && _al.seller != msg.sender);
        _;
    }

    modifier onlyOb(uint256 _o) {
        Appeal memory _al = appeals[_o];
        require(_al.detail.observerAddr == msg.sender);
        require(_al.buyer != msg.sender && _al.seller != msg.sender);
        _;
    }

    modifier onlyBOS(uint256 _o) {
        OrderStorage.Order memory _r = _oSt.searchOrder(_o);
        require(
            _r.orderDetail.sellerAddr == msg.sender ||
                _r.orderDetail.buyerAddr == msg.sender
        );
        _;
    }

    function _insert(uint256 _o, uint256 _count) internal {
        OrderStorage.Order memory _or = _oSt.searchOrder(_o);

        require(appeals[_o].appealNo == uint256(0));

        AppealDetail memory _detail = AppealDetail({
            finalAppealAddr: address(0),
            updateTime: uint256(0),
            witnessReason: "",
            observerReason: "",
            witnessAppealStatus: 0,
            witnessHandleTime: uint256(0),
            observerHandleTime: uint256(0),
            observerAddr: address(0),
            witnessHandleReward: 0,
            observerHandleReward: 0,
            witnessHandleCredit: 0,
            observerHandleCredit: 0,
            witReward: 0,
            witSub: 0,
            witCreditR: 0,
            witCreditS: 0
        });

        uint256 _appealNo = block.timestamp;

        Appeal memory _appeal = Appeal({
            user: msg.sender,
            appealNo: _appealNo,
            orderNo: _o,
            witness: address(0),
            buyer: _or.orderDetail.buyerAddr,
            seller: _or.orderDetail.sellerAddr,
            mortgage: _count,
            status: 1,
            appealTime: block.timestamp,
            witTakeTime: 0,
            obTakeTime: 0,
            detail: _detail
        });

        appeals[_o] = _appeal;

        appealList.push(_appeal);
        appealIndex[_o] = appealList.length - 1;

        chanT(_or.orderDetail.sellerAddr, _or.orderDetail.buyerAddr, 1, 0);

        emit addAppeal(_appealNo, _o);
    }

    function chanT(
        address _seller,
        address _buyer,
        uint256 _t,
        uint256 _r
    ) internal {
        uint256 _tc = _rSt.getTradeCredit();
        uint256 _rs = _rSt.getSubTCredit();

        UserStorage.User memory _user = _uSt.searchUser(_seller);
        UserStorage.TradeStats memory _tr = _user.tradeStats;

        UserStorage.User memory _user2 = _uSt.searchUser(_buyer);
        UserStorage.TradeStats memory _tr2 = _user2.tradeStats;
        uint256 _c2 = _user2.credit;

        uint256 _c = _user.credit;
        if (_t == 1) {
            _tr.tradeTotal = _tr.tradeTotal > 0 ? (_tr.tradeTotal - 1) : 0;
            _tr2.tradeTotal = _tr2.tradeTotal > 0 ? (_tr2.tradeTotal - 1) : 0;

            _c = (_c >= _tc) ? (_c - _tc) : 0;

            _c2 = (_c2 >= _tc) ? (_c2 - _tc) : 0;
        } else if (_t == 2) {
            _tr.tradeTotal += 1;
            _tr2.tradeTotal += 1;

            if (_r == 1) {
                _c += _tc;
                _c2 = (_c2 >= _rs) ? (_c2 - _rs) : 0;
            } else if (_r == 2) {
                _c2 += _tc;
                _c = (_c >= _rs) ? (_c - _rs) : 0;
            }
        }

        _uSt.updateTradeStats(_seller, _tr, _c);
        _uSt.updateTradeStats(_buyer, _tr2, _c2);
    }

    function applyAppeal(uint256 _o) external onlyBOS(_o) {
        uint256 _fee = _rSt.getAppealFee();
        _insert(_o, _fee);

        TokenTransfer _tokenTransfer = _rSt.getERC20Address("WMOVR");
        _tokenTransfer.transferFrom(msg.sender, recAddr, _fee);
    }

    function takeWit(uint256 _o) external {
        Appeal memory _al = appeals[_o];

        require(_al.buyer != msg.sender && _al.seller != msg.sender);

        require(_al.witness == address(0));
        require(_al.status == 1);

        bool _f = witOrOb(1);
        require(_f);

        _al.witness = msg.sender;
        _al.witTakeTime = block.timestamp;

        appeals[_o] = _al;
        appealList[appealIndex[_o]] = _al;
    }

    function takeOb(uint256 _o) external {
        Appeal memory _al = appeals[_o];

        require(_al.buyer != msg.sender && _al.seller != msg.sender);

        require(_al.status == 4 || _al.status == 5);
        require(_al.detail.observerAddr == address(0));

        bool _f = witOrOb(2);
        require(_f);

        _al.detail.observerAddr = msg.sender;
        _al.obTakeTime = block.timestamp;

        appeals[_o] = _al;
        appealList[appealIndex[_o]] = _al;
    }

    function changeHandler(uint256 _o, uint256 _type) external onlyBOS(_o) {
        Appeal memory _al = appeals[_o];

        if (_type == 1) {
            require(_al.status == 1);
            require(_al.witness != address(0));
            require(block.timestamp - _al.witTakeTime > 24 hours);

            _al.witness = address(0);
            _al.witTakeTime = 0;
        } else if (_type == 2) {
            require(_al.status == 4 || _al.status == 5);
            require(_al.detail.observerAddr != address(0));
            require(block.timestamp - _al.obTakeTime > 24 hours);

            _al.detail.observerAddr = address(0);
            _al.obTakeTime = 0;
        }

        appeals[_o] = _al;
        appealList[appealIndex[_o]] = _al;
    }

    function witOrOb(uint256 _f) internal view returns (bool) {
        UserStorage.User memory _u = _uSt.searchUser(msg.sender);
        if (_u.userFlag == _f) {
            return true;
        }
        return false;
    }

    function applyFinal(uint256 _o) external onlyBOS(_o) {
        Appeal memory _al = appeals[_o];

        require(_al.status == 2 || _al.status == 3);

        require(block.timestamp - _al.detail.witnessHandleTime <= 24 hours);

        chanT(_al.seller, _al.buyer, 1, 0);

        uint256 _fee = _rSt.getAppealFeeFinal();

        TokenTransfer _tokenTransfer = _rSt.getERC20Address("WMOVR");
        _tokenTransfer.transferFrom(msg.sender, recAddr, _fee);

        if (_al.status == 2) {
            _al.status = 4;
        } else if (_al.status == 3) {
            _al.status = 5;
        }
        _al.detail.finalAppealAddr = msg.sender;
        _al.detail.updateTime = block.timestamp;
        appeals[_o] = _al;
        appealList[appealIndex[_o]] = _al;
    }

    function witnessOpt(
        uint256 _o,
        string memory _r,
        uint256 _s
    ) external onlyWit(_o) {
        require(_s == 2 || _s == 3);
        Appeal memory _al = appeals[_o];

        require(_al.status == 1);
        uint256 _fee = _rSt.getAppealFee();
        uint256 _rcedit = _rSt.getWitnessHandleCredit();

        _al.status = _s;
        _al.detail.witnessAppealStatus = _s;
        _al.detail.witnessReason = _r;
        _al.detail.witnessHandleTime = block.timestamp;
        _al.detail.witnessHandleReward = _fee;
        _al.detail.witnessHandleCredit = _rcedit;
        _al.detail.witReward = _fee;
        _al.detail.witCreditR = _rcedit;

        _al.detail.updateTime = block.timestamp;
        appeals[_o] = _al;
        appealList[appealIndex[_o]] = _al;

        if (_s == 2) {
            if (_al.user == _al.buyer) {
                _rSt.subAvaAppeal(_al.seller, _al.buyer, _al, _fee, 1, 0);
                chanT(_al.seller, _al.buyer, 2, 2);
            } else if (_al.user == _al.seller) {
                _rSt.subAvaAppeal(_al.buyer, _al.seller, _al, _fee, 1, 0);

                chanT(_al.seller, _al.buyer, 2, 1);
            }
        }

        if (_s == 3) {
            if (_al.user == _al.buyer) {
                _rSt.subAvaAppeal(_al.buyer, _al.seller, _al, _fee, 1, 1);
                chanT(_al.seller, _al.buyer, 2, 1);
            } else if (_al.user == _al.seller) {
                _rSt.subAvaAppeal(_al.seller, _al.buyer, _al, _fee, 1, 1);
                chanT(_al.seller, _al.buyer, 2, 2);
            }
        }
    }

    function observerOpt(
        uint256 _o,
        string memory _r,
        uint256 _s
    ) external onlyOb(_o) {
        require(_s == 6 || _s == 7);
        Appeal memory _appeal = appeals[_o];

        require(_appeal.status == 4 || _appeal.status == 5);
        uint256 _fee = _rSt.getAppealFeeFinal();
        uint256 _rcedit = _rSt.getObserverHandleCredit();

        _appeal.status = _s;
        _appeal.detail.observerReason = _r;
        _appeal.detail.observerHandleTime = block.timestamp;
        _appeal.detail.observerHandleReward = _fee;
        _appeal.detail.observerHandleCredit = _rcedit;

        uint256 _subWC = _rSt.getSubWitCredit();
        uint256 _subWF = _rSt.getSubWitFee();

        if (_s == 6) {
            if (_appeal.user == _appeal.buyer) {
                _rSt.subAvaAppeal(
                    _appeal.seller,
                    _appeal.buyer,
                    _appeal,
                    _fee,
                    2,
                    0
                );

                chanT(_appeal.seller, _appeal.buyer, 2, 2);
                _rSt.subFrozenTotal(_o, _appeal.buyer);
            } else if (_appeal.user == _appeal.seller) {
                _rSt.subAvaAppeal(
                    _appeal.buyer,
                    _appeal.seller,
                    _appeal,
                    _fee,
                    2,
                    0
                );

                chanT(_appeal.seller, _appeal.buyer, 2, 1);
                _rSt.subFrozenTotal(_o, _appeal.seller);
            }
            if (_appeal.detail.witnessAppealStatus == 3) {
                _appeal.detail.witSub = _subWF;
                _appeal.detail.witCreditS = _subWC;

                if (_appeal.detail.witnessHandleCredit >= _subWC) {
                    _appeal.detail.witnessHandleCredit = SafeMath.sub(
                        _appeal.detail.witnessHandleCredit,
                        _subWC
                    );
                } else {
                    _appeal.detail.witnessHandleCredit = 0;
                }
                _rSt.subWitnessAvailable(_appeal.witness);
            }
        }

        if (_s == 7) {
            if (_appeal.user == _appeal.buyer) {
                _rSt.subAvaAppeal(
                    _appeal.buyer,
                    _appeal.seller,
                    _appeal,
                    _fee,
                    2,
                    1
                );
                chanT(_appeal.seller, _appeal.buyer, 2, 1);
                _rSt.subFrozenTotal(_o, _appeal.seller);
            } else if (_appeal.user == _appeal.seller) {
                _rSt.subAvaAppeal(
                    _appeal.seller,
                    _appeal.buyer,
                    _appeal,
                    _fee,
                    2,
                    1
                );
                chanT(_appeal.seller, _appeal.buyer, 2, 2);
                _rSt.subFrozenTotal(_o, _appeal.buyer);
            }
            if (_appeal.detail.witnessAppealStatus == 2) {
                _appeal.detail.witSub = _subWF;
                _appeal.detail.witCreditS = _subWC;

                if (_appeal.detail.witnessHandleCredit >= _subWC) {
                    _appeal.detail.witnessHandleCredit = SafeMath.sub(
                        _appeal.detail.witnessHandleCredit,
                        _subWC
                    );
                } else {
                    _appeal.detail.witnessHandleCredit = 0;
                }
                _rSt.subWitnessAvailable(_appeal.witness);
            }
        }

        _appeal.detail.updateTime = block.timestamp;
        appeals[_o] = _appeal;
        appealList[appealIndex[_o]] = _appeal;
    }

    function searchAppeal(uint256 _o)
        external
        view
        returns (Appeal memory appeal)
    {
        return appeals[_o];
    }

    function searchAppealList() external view returns (Appeal[] memory) {
        return appealList;
    }
}