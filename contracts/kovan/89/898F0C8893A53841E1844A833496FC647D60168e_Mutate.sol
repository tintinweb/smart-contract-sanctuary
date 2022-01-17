/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: contracts/Mutant.sol



pragma solidity >=0.7.0 <0.9.0;


library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

interface IPolygonPenguin {
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Mutate {
    
    using SafeMath for uint256;

    address private constant penguinAddr = 0xeaD5D1eC4F7a647De61a7A0225eeC7387A25BE01;
    mapping(uint256 => bool) public isTrippy;
    mapping(uint256 => bool) public isArctic;
    mapping(uint256 => bool) public isMutant;
    mapping(address => uint256) public currentBonds;
    uint256[] private trippy = [2774,7095,1699,2396,2166,1042,8370,6699,730,4539,2707,6494,848,4722,4894,5021,7839,969,374,5917,1434,8198,2547,7004,1357,5136,8367,5176,7567,4175,8473,7287,2517,5326,3194,4468,7730,621,6077,4921,451,6505,5741,6069,7650,7412,1007,214,583,1893,8882,5285,8777,5985,5126,6033,985,3490,788,4634,1738,802,7666,7386,1385,8403,2930,8241,3545,7417,2002,7863,5894,3361,3982,4281,6805,4041,3632,5488,4271,1551,5731,6697,7836,1075,4574,3383,5538,7076,517,6016,4107,8533,7882,4110,604,5790,1312,6422];
    uint256[] private arctic = [3834,3281,3788,6831,7221,5513,813,4639,3394,6620,3868,8194,7545,3816,8191,4387,1082,511,6412,1942,5526,6338,8713,3460,7345,4661,3158,5470,1944,2926,2136,2614,3554,3085,8662,4225,7907,5281,5617,8425,2289,7918,894,5777,7625,4626,379,1060,2570,514,4240,6897,994,5477,1798,4777,299,317,5061,1159,5821,6790,4104,6667,1975,4244,8377,3482,7267,8872,8759,4161,645,6149,5983,461,457,977,8052,5287,5231,2013,4659,3411,2083,7496,4044,452,7694,3516,8573,2800,7264,6794,4943,8545,437,6089,5576,6198,8417,6930,197,7053,1505,4324,6471,5522,7980,6589,5289,4645,834,8130,5436,6896,2241,667,754,1476,6377,417,7216,642,245,4241,166,527,7001,962,8236,6272,4261,5708,4307,8201,2264,5380,1718,3707,1380,4746,415,6200,2975,3059,5986,3963,7672,5246,6891,1332,2647,383,2845,8491,4121,4318,5898,7158,8028,4482,4130,1950,1883,7957,185,26,5669,1304,5582,7580,7909,6473,5846,4105,7651,1642,476,5951,4187,5888,7269,2462,7131,4730,8696,1759,5693,5744,6941,7810,2368,1813,4144,8445,7869,5092,7380,4106,7951,5630,6981,2079,3103,8832,8157,8810,85,6509,4086,2884,4795,3064,2437,3026,6617,1327,4464,2054,1810,8693,7424,3633,5372,1486,5013,3969,5165,2725,315,4004,484,1103,2057,3009,5387,5270,3005,6915,7754,5081,1422,5732,659,6660,8116,7964,1299,5282,1405,4320,3455,2542,929,6321,8325,2393,757,3844,6945,2878,3916,7325,6598,4798,1726,6010,8740,8789,1287,2332,4329,8008,8649,3664,2363,4786,3777,2179,6131,3656,741,7945,137,2753,7722,5859,3513,2449,3769,6610,80,4263,67,3620,1120,6732,5813,8487,3603,7138,5553,4961,2472,1039,6671,6500,3661,2004,6739,8557,345,207,6091,4294,5668,3349,4259,8271,3477,1923,5355,2034,1550,2852,8443,5245,1751,1575,1102,4655,2630,3380,2307,3256,6887,5619,5624,2348,2674,2908,6328,1691,4422,2489,1542,3742,4443,823,372,4745,3056,8613,5226,7236,3327,2922,3866,1660,3976,5910,6145,55,7751,4081,7983,7229,4944,7140,3282,7762,784,5354,7122,5680,5404,6645,1577,1815,2339,816,4889,3042,3307,856,8727,7408,3356,4353,4248,8026,4220,2306,8040,2165,5031,4565,1012,5097,200,1594,3291,1182,8408,7886,2017,2082,740,3999,1281,943,6631,4647,4203,7186,5026,4156,3204,8256,159,2581,6046,6593,4768,8758,760,720,5427,3555,575,7245,5626,8511,1905,8227,938,2154,1276,7997,646,8183,103,5586,4053,1349,7858,5581,6102,227,8265,3335,6890,3250,6784,2482,7759,4078,7192,3510,5716,6880,2944,2690,354,2695,2676,4299,4065,8019,6968,1582,935,2990,2261,3393,5564,5108,5533,8644,498,8282,169,1671,2157,3124,2142,4159,389,6567,3876,7096,1682,8081,8873,2428,5862,7579,2514,1114,7165,4638,4414,3749,4348,4930,1432,6452,2714,6821,15,3093,2212,8372,8877,955,4169,3209,4958,3753,6986,3372,477,8165,4014,7286,4760,2346,173,5881,2401,724,8677,1961,5550,2880,5150,5911,4741,2168,1026,5397,5219,6194,2703,2355,3922,1658,3421,4803,6989,1932,763,1622,1324,7729,4410,2709,4598,8530,2206,1323,1830,2603,4091,7517,2143,4228,5972,3376,7240,6663,408,4009,4393,3265,4762,1310,4648,7449,1450,2873,2702,4592,1321,3998,687,4048,1225,4435,3529,5385,5519,501,1244,3543,3369,2402,5721,2316,7169,1747,824,6980,5755,3152,4124,421,5212,5389,4679,5122,8821,2282,6791,1967,6370,1507,7198,3098,1636,249,4752,606,2214,4992,5018,3689,2444,6548,3348,6527,5717,5358,2484,7214,4896,7363,3879,1188,8300,563,631,7676,4544,6876,648,3892,6582,6653,8123,433,2379,6100,3428,2487,500,6024,8419,7716,4027,2980,5452,2505,5596,8560,2979,1949,3096,5403,3424,4743,8187,6687,7351,6787,6767,3435,652,1936,16,2773,2080,7185,320,1177,8691,7344,7146,3037,8371,3136,1753,5366,1126,8738,8029,7147,2623,1812,4207,3326,8171,6547,4379,2003,6893,4727,6166,8523,7161,2298,556,2586,7865,3845,5808,6747,1164,2740,5832,8135,3413,6785,4636,1454,8087,7064,1101,6426,1669,5546,8685,6522,3811,7391,7075,3395,7592,896,7411,4640,4438,2617,3344,4349,4784,183,6213,6111,4260,4089,8683,5799,599,1427,4980,96,3082,4278,3207,3887,1425,3943,5056,7461,3497,2326,5672,4407,5609,1315,2816,3994,487,3893,3820,2414,3269,6602,6219,3688,6351,1261,7310,4828,4522,2435,5770,5093,1573,5360,5644,7443,2599,2754,7334,6217,2966,6644,266,5976,363,5865,4457,1814,3532,302,7487,3328,3496,3619,8434,1381,6119,8519,2752,5181,6651,1817,4007,4100,57,4735,1797,2019,2755,6329,7457,3216,5868,4265,8485,2534,8364,2312,3352,7550,7520,5147,7739,2383,5897,5853,5481,7153,69,4542,550,3931,7057,6863,1680,2479,5255,6560,2766,7187,2777,7577,4166,1209,5370,7059,6808,7160,5279,3446,4388,5298,6870,4133,2610,2183,714,6568,5364,4824,4343,1262,6744,1479,2497,3855,8374,3454,2362];
    uint256[] private mutant;
    address[] private bondedAddresses;
    uint256 public mutateFee;
    uint256 public bonds;
    uint256 public bondsRemaining;
    uint256 public maxBondsperUser;
    address payable internal farmingAddr;
    address payable internal deployer;
    address payable internal developer;


    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }


    constructor(address payable _farmAddr, address payable _deployer, address payable _developer) {
        farmingAddr = _farmAddr;
        deployer = _deployer;
        developer = _developer;
    }

    function deposit() public payable {}

    function isEligible(uint256 penguinId) public returns (bool) {
        if (isTrippy[penguinId] == true || isArctic[penguinId] == true) {
            return false;
        } else {
            return true;
        }
    }

    function getTrippies() public view returns (uint256[] memory) {
        return trippy;
    }

    function getMutant() public view returns (uint256[] memory) {
        return mutant;
    }

    function changeFee(uint256 _fee) public onlyDeployer {
        mutateFee = _fee;
    }

    function withdrawERC20(
        IERC20 token,
        address payable destination,
        uint256 amount
    ) public onlyDeployer {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "Insufficient funds");
        token.transfer(destination, amount);
        //emit Transfered(msg.sender, destination, amount);
    }

    function createMappings() public onlyDeployer {
        for (uint256 i = 0; i < trippy.length; i++) {
            isTrippy[trippy[i]] = true;
        }
        for (uint256 i = 0; i < arctic.length; i++) {
            isArctic[arctic[i]] = true;
        }
    }

    function setBonds(uint protocol_amount, uint user_amount, uint set_fee) public onlyDeployer {
        bonds = protocol_amount;
        maxBondsperUser = user_amount;
        bondsRemaining = bonds;
        mutateFee = set_fee;
    }

    function setBondFee(uint fee) public onlyDeployer {
        mutateFee = fee;
    }

    function clearBonds() public onlyDeployer{
        for (uint256 i = 0; i < bondedAddresses.length; i++) {
            currentBonds[bondedAddresses[i]] = 0;
        }
    }

    function mutate(uint256 penguinId) external payable {
        require(bondsRemaining > 0, "no bonds left");
        require(currentBonds[msg.sender] < maxBondsperUser, "max bonds hit");
        //require(IPolygonPenguin(penguinAddr).ownerOf(penguinId) == msg.sender, "you don't own this penguin ser");
        require(msg.value == mutateFee, "fee sent not correct");
        require(isEligible(penguinId), "penguin not eligible");
        require(!isMutant[penguinId], "already mutated penguin");
        bondedAddresses.push(msg.sender);
        developer.transfer(msg.value.div(10));
        farmingAddr.transfer(msg.value);
        isMutant[penguinId] = true;
        currentBonds[msg.sender] += 1;
        bondsRemaining -= 1;
        mutant.push(penguinId);
    }
}