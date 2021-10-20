/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

pragma solidity 0.5.17;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) 
            return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = add(x >> 1, 1);
        uint256 y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
        return y;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library Address {
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
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Oracle {
    function latestAnswer() external view returns (int256);
}

contract HakkaIntelligence {
    using SafeMath for *;
    using SafeERC20 for IERC20;

    IERC20 public token;

    uint256 public totalStake;
    uint256 public revealedStake;
    uint256 public totalScore;
    uint256 public offset;

    // timeline
    //                          poke                     poke
    // deploy contract ---- period start ---- period stop-|-reveal open --- reveal close～～～
    //        \----- can bet -----/                        \---- must reveal----/  \---can claim--

    uint256 public periodStart;
    uint256 public periodStop;
    uint256 public revealOpen;
    uint256 public revealClose;

    uint256 public elementCount;
    address[] public oracles;
    uint256[] public priceSnapshot;
    uint256[] public answer;

    struct Player {
        bool revealed;
        bool claimed;
        uint256 stake;
        uint256 score;
        uint256[] submission;
    }

    mapping(address => Player) public players;

    event Submit(address indexed player, uint256[] submission);
    event Reveal(address indexed player, uint256 score);
    event Claim(address indexed player, uint256 amount);

    constructor(address[] memory _oracles, address _token, uint256 _periodStart, uint256 _periodStop) public {
        oracles = _oracles;
        elementCount = _oracles.length;
        token = IERC20(_token);
        periodStart = _periodStart;
        periodStop = _periodStop;
    }

    function calcLength(uint256[] memory vector) public pure returns (uint256 l) {
        for(uint256 i = 0; i < vector.length; i++)
            l = l.add(vector[i].mul(vector[i]));
        l = l.sqrt();
    }

    function innerProduct(uint256[] memory vector1, uint256[] memory vector2) public pure returns (uint256 xy) {
        require(vector1.length == vector2.length, "different dimension");
        for(uint256 i = 0; i < vector1.length; i++)
            xy = xy.add(vector1[i].mul(vector2[i]));
    }

    function playerSubmission(address _player) external view returns (uint256[] memory submission) {
        Player storage player = players[_player];
        return player.submission;
    }

    function submit(uint256 stake, uint256[] memory submission) public {
        Player storage player = players[msg.sender];

        require(now <= periodStart, "too late");
        require(submission.length == elementCount, "invalid input count");
        require(player.submission.length == 0, "already submitted");
        require(calcLength(submission) <= 1e18, "invalid input length");

        totalStake = totalStake.add(stake);
        player.stake = stake;

        player.submission = submission;
        token.safeTransferFrom(msg.sender, address(this), stake);
        emit Submit(msg.sender, submission);
    }

    function reveal(address _player) public returns (uint256 score) {
        Player storage player = players[_player];

        require(!player.revealed, "revealed");
        require(now >= revealOpen, "not yet");
        require(now <= revealClose, "too late");
        score = innerProduct(answer, player.submission);
        score = score.mul(score).div(1e36); //score = score^2
        score = score.mul(player.stake).div(1e36);
        revealedStake = revealedStake.add(player.stake);
        player.revealed = true;
        player.score = score;
        totalScore = totalScore.add(score);

        emit Reveal(_player, score);
    }

    function claim(address _player) public returns (uint256 amount) {
        Player storage player = players[_player];

        require(now > revealClose, "not yet");
        require(!player.claimed, "claimed");
        player.claimed = true;
        amount = token.balanceOf(address(this)).mul(player.score).div(totalScore.sub(offset));
        offset = offset.add(player.score);
        token.safeTransfer(_player, amount);

        emit Claim(_player, amount);
    }

    function proceed() public {
        if(priceSnapshot.length == 0) {
            require(now >= periodStart, "not yet");
            for(uint256 i = 0; i < elementCount; i++) {
                uint256 price = uint256(Oracle(oracles[i]).latestAnswer());
                require(price > 0, "invalid oracle response");
                priceSnapshot.push(price);
            }
        }
        else if(answer.length == 0) {
            require(now >= periodStop, "not yet");
            uint256[] memory _answer = new uint256[](elementCount);
            for(uint256 i = 0; i < elementCount; i++)
                _answer[i] = uint256(Oracle(oracles[i]).latestAnswer()).mul(1e18).div(priceSnapshot[i]);
            uint256 _length = calcLength(_answer).add(1);
            for(uint256 i = 0; i < elementCount; i++)
                _answer[i] = _answer[i].mul(1e18).div(_length);
            answer = _answer;
            revealOpen = now;
            revealClose = now.add(14 days);
        }
        else revert();
    }

}