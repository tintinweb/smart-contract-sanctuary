pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract DEC is ERC20, AccessControl {

    using Address for address;

    using SafeMath for uint256;

    address public _default_admin;

    uint256 public constant INVITE_AMOUNT = 0.01 * 10 ** 18;

    uint256 public constant RECEIPT_AMOUNT = 0.01 * 10 ** 18;

    uint256 public constant BACK_AMOUNT = 10 * 10 ** 18;

    uint256 public constant INIT_COUNT = 10000;

    uint256 public start_time = 0;

    uint256 public start_issue = 0;

    uint256 public constant DISCOUNT_AMOUNT = 10000 * 10 ** 18;

    uint256 public constant MIN_AMOUNT = 20000 * 10 ** 18;

    uint256[] public issueInfo;

    uint256 public constant MONTH_SECONDS = 30 * 24 * 60 * 60;

    uint256 public constant DAY_SECONDS = 24 * 60 * 60;

    bytes32 public constant DEC_ROLE = keccak256("DEC_ROLE");

    bytes32 public constant INIT_ROLE = keccak256("INIT_ROLE");

    bytes32 public constant INIT_HIS_ROLE = keccak256("INIT_HIS_ROLE");

    mapping(address => address) public relation;

    mapping(address => uint256) public invitor;

    mapping(address => uint256) public discounts;

    // 880000000 - 97000000 = 783000000
    uint256 public constant INIT_MINE_SUPPLY = 97000000 * 10 ** 18;

    uint256 public constant TOTAL_ISSUE = 8.8 * 10 ** 8 * 10 ** 18;

    uint256 public surplusAmount = 7.83 * 10 ** 8 * 10 ** 18;

    uint256 public issuedAmount = INIT_MINE_SUPPLY;

    constructor(address default_admin) public ERC20("DEC", "DEC") payable{
        require(!(default_admin.isContract()) && default_admin != address(0), "default_admin address must not contract address or 0x.");
        _default_admin = default_admin;

        _setupRole(DEFAULT_ADMIN_ROLE, default_admin);
        _setupRole(INIT_HIS_ROLE, _msgSender());
        _mint(default_admin, INIT_MINE_SUPPLY);

        issueInfo.push(6600000 * 10 ** 18);
        issueInfo.push(6567000 * 10 ** 18);
        issueInfo.push(6534165 * 10 ** 18);
        issueInfo.push(6501494.175 * 10 ** 18);
        issueInfo.push(6468986.704124999 * 10 ** 18);
        issueInfo.push(6436641.770604375 * 10 ** 18);
        issueInfo.push(6404458.561751354 * 10 ** 18);
        issueInfo.push(6372436.268942596 * 10 ** 18);
        issueInfo.push(6340574.087597883 * 10 ** 18);
        issueInfo.push(6308871.217159893 * 10 ** 18);
        issueInfo.push(6277326.861074095 * 10 ** 18);
        issueInfo.push(6245940.226768724 * 10 ** 18);
        issueInfo.push(6214710.52563488 * 10 ** 18);
        issueInfo.push(6183636.973006706 * 10 ** 18);
        issueInfo.push(6152718.7881416725 * 10 ** 18);
        issueInfo.push(6121955.194200964 * 10 ** 18);
        issueInfo.push(6091345.418229959 * 10 ** 18);
        issueInfo.push(6060888.691138809 * 10 ** 18);
        issueInfo.push(6030584.247683115 * 10 ** 18);
        issueInfo.push(6000431.326444699 * 10 ** 18);
        issueInfo.push(5970429.169812476 * 10 ** 18);
        issueInfo.push(5940577.023963413 * 10 ** 18);
        issueInfo.push(5910874.138843597 * 10 ** 18);
        issueInfo.push(5881319.768149379 * 10 ** 18);
        issueInfo.push(5851913.169308632 * 10 ** 18);
        issueInfo.push(5822653.603462089 * 10 ** 18);
        issueInfo.push(5793540.335444777 * 10 ** 18);
        issueInfo.push(5764572.633767554 * 10 ** 18);
        issueInfo.push(5735749.770598715 * 10 ** 18);
        issueInfo.push(5707071.021745723 * 10 ** 18);
        issueInfo.push(5678535.666636994 * 10 ** 18);
        issueInfo.push(5650142.988303809 * 10 ** 18);
        issueInfo.push(5621892.27336229 * 10 ** 18);
        issueInfo.push(5593782.811995478 * 10 ** 18);
        issueInfo.push(5565813.8979355 * 10 ** 18);
        issueInfo.push(5537984.828445823 * 10 ** 18);
        issueInfo.push(5510294.904303594 * 10 ** 18);
        issueInfo.push(5482743.429782077 * 10 ** 18);
        issueInfo.push(5455329.7126331655 * 10 ** 18);
        issueInfo.push(5428053.064069999 * 10 ** 18);
        issueInfo.push(5400912.79874965 * 10 ** 18);
        issueInfo.push(5373908.234755902 * 10 ** 18);
        issueInfo.push(5347038.693582122 * 10 ** 18);
        issueInfo.push(5320303.500114212 * 10 ** 18);
        issueInfo.push(5293701.982613641 * 10 ** 18);
        issueInfo.push(5267233.472700572 * 10 ** 18);
        issueInfo.push(5240897.30533707 * 10 ** 18);
        issueInfo.push(5214692.818810385 * 10 ** 18);
        issueInfo.push(5188619.354716333 * 10 ** 18);
        issueInfo.push(5162676.25794275 * 10 ** 18);
        issueInfo.push(5136862.876653036 * 10 ** 18);
        issueInfo.push(5111178.5622697715 * 10 ** 18);
        issueInfo.push(5085622.669458422 * 10 ** 18);
        issueInfo.push(5060194.55611113 * 10 ** 18);
        issueInfo.push(5034893.583330574 * 10 ** 18);
        issueInfo.push(5009719.115413922 * 10 ** 18);
        issueInfo.push(4984670.519836852 * 10 ** 18);
        issueInfo.push(4959747.167237667 * 10 ** 18);
        issueInfo.push(4934948.431401479 * 10 ** 18);
        issueInfo.push(4910273.689244472 * 10 ** 18);
        issueInfo.push(4885722.32079825 * 10 ** 18);
        issueInfo.push(4861293.709194259 * 10 ** 18);
        issueInfo.push(4836987.240648287 * 10 ** 18);
        issueInfo.push(4812802.304445045 * 10 ** 18);
        issueInfo.push(4788738.292922821 * 10 ** 18);
        issueInfo.push(4764794.601458206 * 10 ** 18);
        issueInfo.push(4740970.628450915 * 10 ** 18);
        issueInfo.push(4717265.77530866 * 10 ** 18);
        issueInfo.push(4693679.446432117 * 10 ** 18);
        issueInfo.push(4670211.0491999565 * 10 ** 18);
        issueInfo.push(4646859.993953956 * 10 ** 18);
        issueInfo.push(4623625.693984187 * 10 ** 18);
        issueInfo.push(4600507.5655142665 * 10 ** 18);
        issueInfo.push(4577505.027686695 * 10 ** 18);
        issueInfo.push(4554617.502548262 * 10 ** 18);
        issueInfo.push(4531844.41503552 * 10 ** 18);
        issueInfo.push(4509185.192960343 * 10 ** 18);
        issueInfo.push(4486639.266995541 * 10 ** 18);
        issueInfo.push(4464206.070660563 * 10 ** 18);
        issueInfo.push(4441885.04030726 * 10 ** 18);
        issueInfo.push(4419675.615105723 * 10 ** 18);
        issueInfo.push(4397577.237030195 * 10 ** 18);
        issueInfo.push(4375589.350845044 * 10 ** 18);
        issueInfo.push(4353711.404090819 * 10 ** 18);
        issueInfo.push(4331942.847070364 * 10 ** 18);
        issueInfo.push(4310283.132835013 * 10 ** 18);
        issueInfo.push(4288731.717170838 * 10 ** 18);
        issueInfo.push(4267288.058584983 * 10 ** 18);
        issueInfo.push(4245951.618292059 * 10 ** 18);
        issueInfo.push(4224721.860200599 * 10 ** 18);
        issueInfo.push(4203598.250899595 * 10 ** 18);
        issueInfo.push(4182580.259645097 * 10 ** 18);
        issueInfo.push(4161667.3583468716 * 10 ** 18);
        issueInfo.push(4140859.0215551374 * 10 ** 18);
        issueInfo.push(4120154.7264473615 * 10 ** 18);
        issueInfo.push(4099553.952815125 * 10 ** 18);
        issueInfo.push(4079056.1830510492 * 10 ** 18);
        issueInfo.push(4058660.902135794 * 10 ** 18);
        issueInfo.push(4038367.597625115 * 10 ** 18);
        issueInfo.push(4018175.7596369893 * 10 ** 18);
        issueInfo.push(3998084.8808388044 * 10 ** 18);
        issueInfo.push(3978094.4564346103 * 10 ** 18);
        issueInfo.push(3958203.9841524367 * 10 ** 18);
        issueInfo.push(3938412.9642316755 * 10 ** 18);
        issueInfo.push(3918720.899410517 * 10 ** 18);
        issueInfo.push(3899127.2949134647 * 10 ** 18);
        issueInfo.push(3879631.6584388968 * 10 ** 18);
        issueInfo.push(3860233.5001467024 * 10 ** 18);
        issueInfo.push(3840932.332645969 * 10 ** 18);
        issueInfo.push(3821727.6709827394 * 10 ** 18);
        issueInfo.push(3802619.032627825 * 10 ** 18);
        issueInfo.push(3783605.9374646856 * 10 ** 18);
        issueInfo.push(3764687.907777363 * 10 ** 18);
        issueInfo.push(3745864.468238476 * 10 ** 18);
        issueInfo.push(3727135.145897283 * 10 ** 18);
        issueInfo.push(3708499.4701677966 * 10 ** 18);
        issueInfo.push(3689956.9728169576 * 10 ** 18);
        issueInfo.push(3671507.187952873 * 10 ** 18);
        issueInfo.push(3653149.652013109 * 10 ** 18);
        issueInfo.push(3634883.903753043 * 10 ** 18);
        issueInfo.push(3616709.484234278 * 10 ** 18);
        issueInfo.push(3598625.9368131068 * 10 ** 18);
        issueInfo.push(3580632.8071290413 * 10 ** 18);
        issueInfo.push(3562729.643093396 * 10 ** 18);
        issueInfo.push(3544915.9948779284 * 10 ** 18);
        issueInfo.push(3527191.4149035392 * 10 ** 18);
        issueInfo.push(3509555.457829022 * 10 ** 18);
        issueInfo.push(3492007.6805398767 * 10 ** 18);
        issueInfo.push(3474547.642137177 * 10 ** 18);
        issueInfo.push(3457174.903926491 * 10 ** 18);
        issueInfo.push(3439889.029406858 * 10 ** 18);
        issueInfo.push(3422689.584259824 * 10 ** 18);
        issueInfo.push(3405576.1363385255 * 10 ** 18);
        issueInfo.push(3388548.255656833 * 10 ** 18);
        issueInfo.push(3371605.514378548 * 10 ** 18);
        issueInfo.push(3354747.486806656 * 10 ** 18);
        issueInfo.push(3337973.7493726225 * 10 ** 18);
        issueInfo.push(3321283.880625759 * 10 ** 18);
        issueInfo.push(3304677.46122263 * 10 ** 18);
        issueInfo.push(3288154.073916517 * 10 ** 18);
        issueInfo.push(3271713.303546935 * 10 ** 18);
        issueInfo.push(3255354.7370291995 * 10 ** 18);
        issueInfo.push(3239077.963344054 * 10 ** 18);
        issueInfo.push(3222882.573527334 * 10 ** 18);
        issueInfo.push(3206768.160659697 * 10 ** 18);
        issueInfo.push(3190734.3198563983 * 10 ** 18);
        issueInfo.push(3174780.6482571163 * 10 ** 18);
        issueInfo.push(3158906.7450158307 * 10 ** 18);
        issueInfo.push(3143112.2112907516 * 10 ** 18);
        issueInfo.push(3127396.650234298 * 10 ** 18);
        issueInfo.push(3111759.666983126 * 10 ** 18);
        issueInfo.push(3096200.8686482105 * 10 ** 18);
        issueInfo.push(3080719.8643049696 * 10 ** 18);
        issueInfo.push(3065316.264983445 * 10 ** 18);
        issueInfo.push(3049989.6836585277 * 10 ** 18);
        issueInfo.push(3034739.735240235 * 10 ** 18);
        issueInfo.push(3019566.0365640335 * 10 ** 18);
        issueInfo.push(3004468.2063812134 * 10 ** 18);
        issueInfo.push(2989445.865349307 * 10 ** 18);
        issueInfo.push(2974498.6360225608 * 10 ** 18);
        issueInfo.push(2959626.1428424483 * 10 ** 18);
        issueInfo.push(2944828.012128236 * 10 ** 18);
        issueInfo.push(2930103.8720675944 * 10 ** 18);
        issueInfo.push(2915453.3527072566 * 10 ** 18);
        issueInfo.push(2900876.0859437203 * 10 ** 18);
        issueInfo.push(2886371.7055140017 * 10 ** 18);
        issueInfo.push(2871939.846986432 * 10 ** 18);
        issueInfo.push(2857580.1477515 * 10 ** 18);
        issueInfo.push(2843292.247012742 * 10 ** 18);
        issueInfo.push(2829075.7857776782 * 10 ** 18);
        issueInfo.push(2814930.40684879 * 10 ** 18);
        issueInfo.push(2800855.754814546 * 10 ** 18);
        issueInfo.push(2786851.476040473 * 10 ** 18);
        issueInfo.push(2772917.218660271 * 10 ** 18);
        issueInfo.push(2759052.6325669694 * 10 ** 18);
        issueInfo.push(2745257.3694041343 * 10 ** 18);
        issueInfo.push(2731531.082557114 * 10 ** 18);
        issueInfo.push(2717873.4271443286 * 10 ** 18);
        issueInfo.push(2704284.060008607 * 10 ** 18);
        issueInfo.push(2690762.6397085637 * 10 ** 18);
        issueInfo.push(2677308.8265100205 * 10 ** 18);
        issueInfo.push(2663922.2823774708 * 10 ** 18);
        issueInfo.push(2650602.670965583 * 10 ** 18);
    }


    function issueInfoLength() external view returns (uint256) {
        return issueInfo.length;
    }

    function currentCanIssueAmount() public view returns (uint256){
        uint256 currentTime = block.timestamp;
        if (currentTime <= start_issue || start_issue <= 0) {
            return 0;
        }

        uint256 timeInterval = currentTime - start_issue;
        uint256 monthIndex = timeInterval.div(MONTH_SECONDS);
        uint256 dayIndex = timeInterval.div(DAY_SECONDS);

        if (monthIndex < 1) {
            return issueInfo[monthIndex].div(30).mul(dayIndex).add(INIT_MINE_SUPPLY).sub(issuedAmount);
        } else if (monthIndex < issueInfo.length) {
            uint256 tempTotal = INIT_MINE_SUPPLY;
            for (uint256 j = 0; j < monthIndex; j++) {
                tempTotal = tempTotal.add(issueInfo[j]);
            }
            uint256 calcAmount = dayIndex.sub(monthIndex.mul(30)).mul(issueInfo[monthIndex].div(30)).add(tempTotal);
            if (calcAmount > TOTAL_ISSUE) {
                return TOTAL_ISSUE.sub(issuedAmount);
            }
            return calcAmount.sub(issuedAmount);
        } else {
            return TOTAL_ISSUE.sub(issuedAmount);
        }
    }

    function currentDayCanIssueAmount() public view returns (uint256){
        uint256 currentTime = block.timestamp;
        if (currentTime <= start_issue || start_issue == 0) {
            return 0;
        }
        uint256 timeInterval = currentTime - start_issue;
        uint256 monthIndex = timeInterval.div(MONTH_SECONDS);
        uint256 dayIndex = timeInterval.div(DAY_SECONDS);
        if (monthIndex < 1) {
            return issueInfo[monthIndex].div(30);
        } else if (monthIndex < issueInfo.length) {
            uint256 tempTotal = INIT_MINE_SUPPLY;
            for (uint256 j = 0; j < monthIndex; j++) {
                tempTotal = tempTotal.add(issueInfo[j]);
            }
            uint256 actualDayIssue = issueInfo[monthIndex].div(30);
            uint256 calcAmount = dayIndex.sub(monthIndex.mul(30)).mul(issueInfo[monthIndex].div(30)).add(tempTotal);
            if (calcAmount > TOTAL_ISSUE) {
                if (calcAmount.sub(TOTAL_ISSUE) <= actualDayIssue) {
                    return actualDayIssue.sub(calcAmount.sub(TOTAL_ISSUE));
                }
                return 0;
            }
            return actualDayIssue;
        } else {
            return 0;
        }

    }

    function issueAnyOne() public {
        if (surplusAmount == 0) {
            return;
        }

        uint256 currentCanIssue = currentCanIssueAmount();
        if (currentCanIssue > 0) {
            if (surplusAmount < currentCanIssue) {
                currentCanIssue = surplusAmount;
            }

            surplusAmount = surplusAmount.sub(currentCanIssue);
            issuedAmount = issuedAmount.add(currentCanIssue);
            _mint(address(this), currentCanIssue);
        }
    }

    function startIssue() public hasDefaultAdminRole {
        require(start_issue <= 0, "can't set,already start");
        start_issue = block.timestamp;
    }

    function start() public hasDefaultAdminRole {
        require(start_time <= 0, "can't set,already start");
        start_time = block.timestamp;
    }

    modifier hasInitHisRole() {
        require(hasRole(INIT_HIS_ROLE, _msgSender()), "Caller is not a init admin");
        _;
    }

    modifier hasDefaultAdminRole() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _;
    }


    function initRoot(address[] memory nodes) public hasInitHisRole {
        require(start_time <= 0, "can't init header, already start");
        require(nodes.length > 0, "Init header array must greater than zero.");
        for(uint i = 0; i < nodes.length; i++){
            address node = nodes[i];
            if(!(node.isContract()) && !hasRole(INIT_ROLE, node)) {
                _setupRole(INIT_ROLE, node);
                _setupRole(DEC_ROLE, node);
            }
        }
    }


    function initRelation(address[] memory children, address[] memory roots) public hasInitHisRole {
        require(start_time <= 0, "can't init relation, already start");
        require(children.length > 0 && roots.length > 0 && children.length == roots.length, "children and roots is empty.");

        for(uint i = 0; i < children.length; i++){
            address root = roots[i];
            address child = children[i];

            if(!(child.isContract()) && relation[child] == address(0)
                    && hasRole(DEC_ROLE, root) && !hasRole(DEC_ROLE, child)) {
                relation[child] = root;
                _setupRole(DEC_ROLE, child);
                invitor[root] = invitor[root].add(1);
                if (invitor[root] == 10) {
                    discounts[root] = DISCOUNT_AMOUNT;
                }
            }
        }
    }


    function _beforeTokenTransfer(address from, address to, uint256 value) internal virtual override {
        if (!(to.isContract()) && !(from.isContract()) && value >= INVITE_AMOUNT && relation[from] == address(0) && !hasRole(DEC_ROLE, from) && hasRole(DEC_ROLE, to)) {
            relation[from] = to;
            _setupRole(DEC_ROLE, from);
            invitor[to] = invitor[to].add(1);
            if (invitor[to] == 10) {
                discounts[to] = DISCOUNT_AMOUNT;
            }
        }
        super._beforeTokenTransfer(from, to, value);
    }

    function withdrawETH() public hasDefaultAdminRole {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawToken(address addr) public hasDefaultAdminRole {
        if (addr == address(this)) {
            _transfer(address(this), _msgSender(), balanceOf(address(this)));
        } else {
            ERC20(addr).transfer(_msgSender(), ERC20(addr).balanceOf(address(this)));
        }
    }

    receive() external payable {
        if (!(Address.isContract(_msgSender())) && getRoleMemberCount(INIT_ROLE) < INIT_COUNT && start_time > 0 && uint256(block.timestamp) <= start_time.add(30 * 24 * 60 * 60)) {
            if (!hasRole(INIT_ROLE, _msgSender()) && msg.value >= RECEIPT_AMOUNT) {
                _setupRole(INIT_ROLE, _msgSender());
                _setupRole(DEC_ROLE, _msgSender());
                ERC20(address(this)).transfer(_msgSender(), BACK_AMOUNT);
            }
        }
    }
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, _msgSender()));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

