//SourceUnit: VoteContract.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: UNLICENSED

import "./commonlib1.sol";

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract VoteContract is Ownable {

    struct Vote {
        string title;
        string data;
        uint256 yes;
        uint256 no;
        bool start;
    }

    IERC20 token = IERC20(0x418aa2f0078770ac737002c66cfb54f2475b0b795a);
    Vote[] public voteData;
    mapping(address => uint256) public userVote;

    function toVote(uint256 _index, bool yesOrNo) external {
        Vote storage vote = voteData[_index];
        require(vote.start, "already end");
        uint256 userCount = userVote[msg.sender];
        uint256 userBalance = getTokenBalance(msg.sender) / 1000000;
        require(userBalance - userCount >= 1, "already vote");
        if (yesOrNo) {
            vote.yes = vote.yes + 1;
        } else {
            vote.no = vote.no + 1;
        }

        userVote[msg.sender] = userVote[msg.sender] + 1;
    }

    function getTokenBalance(address _account) public view returns(uint256) {
        return token.balanceOf(_account);
    }

    function addVote(string calldata _title, string calldata _data) external onlyOwner {
        voteData.push(Vote({
        title : _title,
        data : _data,
        yes : 0,
        no : 0,
        start : true
        }));
    }

    function updateTitle(uint256 _index, string calldata _title) external onlyOwner {
        Vote storage vote = voteData[_index];
        vote.title = _title;
    }

    function updateData(uint256 _index, string calldata _data) external onlyOwner {
        Vote storage vote = voteData[_index];
        vote.data = _data;
    }

    function updateStart(uint256 _index, bool _end) external onlyOwner {
        Vote storage vote = voteData[_index];
        vote.start = _end;
    }

    function getVoteCount() public view returns(uint256) {
        return (token.balanceOf(msg.sender) / 1e6) - userVote[msg.sender];
    }

    function getVote(uint256 page, uint256 size) external view returns(string[] memory _title, string[] memory _data, uint256[] memory _yes, uint256[] memory _no, bool[] memory _st) {
        _title = new string[](size);
        _data = new string[](size);
        _yes = new uint256[](size);
        _no = new uint256[](size);
        _st = new bool[](size);
        if (page > 0) {
            uint256 startIndex = (page - 1) * size;
            for (uint256 i = 0; i < size; i++) {
                if (startIndex + i >= voteData.length) {
                    break;
                }
                _title[i] = voteData[startIndex + i].title;
                _data[i] = voteData[startIndex + i].data;
                _yes[i] = voteData[startIndex + i].yes;
                _no[i] = voteData[startIndex + i].no;
                _st[i] = voteData[startIndex + i].start;
            }
        }
    }
}


//SourceUnit: commonlib1.sol

pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}