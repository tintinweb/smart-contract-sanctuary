/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-28
*/

/**
 *Submitted for verification at Etherscan.io on 2018-09-01
*/

pragma solidity 0.5.8; 

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.



contract DistibutionContract1 is Pausable {
    using SafeMath for uint256;

    uint256 constant public decimals = 1 ether;
    address[] public tokenOwners ; /* Tracks distributions mapping (iterable) */
    uint256 public TGEDate = 0; /* Date From where the distribution starts (TGE) */
    uint256 constant public month = 30 days;
    uint256 constant public year = 365 days;
    uint256 public lastDateDistribution = 0;
    
    mapping(address => DistributionStep[]) public distributions; /* Distribution object */
    
    ERC20 public erc20;

    struct DistributionStep {
        uint256 amountAllocated;
        uint256 currentAllocated;
        uint256 unlockDay;
        uint256 amountSent;
    }

    constructor() public{
        
        setInitialDistribution(0xe4Fd5C4Fe682e640d7Af394ffE29e09D085990ea, 3000000, 0 /* No Lock */);

        /* Private 1*/
        setInitialDistribution(0x9b5199F6FCC5996c7728B89Ec819eb3362BcbdCb, 60000, month);
        setInitialDistribution(0x9b5199F6FCC5996c7728B89Ec819eb3362BcbdCb, 60000, 2*month);
        setInitialDistribution(0x9b5199F6FCC5996c7728B89Ec819eb3362BcbdCb, 60000, 3*month);

        setInitialDistribution(0xE2deeE4e473fBAe7abe7EFB28e171EB767aB7885, 80000, month);
        setInitialDistribution(0xE2deeE4e473fBAe7abe7EFB28e171EB767aB7885, 80000, 2*month);
        setInitialDistribution(0xE2deeE4e473fBAe7abe7EFB28e171EB767aB7885, 80000, 3*month);

        setInitialDistribution(0xa3C6116fb89c57027fBFF48E49f80750452E6CbD, 110000, month);
        setInitialDistribution(0xa3C6116fb89c57027fBFF48E49f80750452E6CbD, 110000, 2*month);
        setInitialDistribution(0xa3C6116fb89c57027fBFF48E49f80750452E6CbD, 110000, 3*month);

        setInitialDistribution(0x38b2d1860e7eB0e0b0566228B7269EcB8460b751, 30000, month);
        setInitialDistribution(0x38b2d1860e7eB0e0b0566228B7269EcB8460b751, 30000, 2*month);
        setInitialDistribution(0x38b2d1860e7eB0e0b0566228B7269EcB8460b751, 30000, 3*month);

        setInitialDistribution(0x9455FD942cA87446fD914e07C403C785bdcdE84E, 100000, month);
        setInitialDistribution(0x9455FD942cA87446fD914e07C403C785bdcdE84E, 100000, 2*month);
        setInitialDistribution(0x9455FD942cA87446fD914e07C403C785bdcdE84E, 100000, 3*month);

        setInitialDistribution(0x764836512832bF31e83fA91Fe4E9216B9E644296, 100000, month);
        setInitialDistribution(0x764836512832bF31e83fA91Fe4E9216B9E644296, 100000, 2*month);
        setInitialDistribution(0x764836512832bF31e83fA91Fe4E9216B9E644296, 100000, 3*month);

        setInitialDistribution(0xe234C800e5EB80920345E858e2246e1c62395BF4, 50000, month);
        setInitialDistribution(0xe234C800e5EB80920345E858e2246e1c62395BF4, 50000, 2*month);
        setInitialDistribution(0xe234C800e5EB80920345E858e2246e1c62395BF4, 50000, 3*month);

        setInitialDistribution(0x52E7bdE89Fcbd1e1C656Db1C08DdE45D82447e25, 75000, month);
        setInitialDistribution(0x52E7bdE89Fcbd1e1C656Db1C08DdE45D82447e25, 75000, 2*month);
        setInitialDistribution(0x52E7bdE89Fcbd1e1C656Db1C08DdE45D82447e25, 75000, 3*month);

        setInitialDistribution(0xeb1eF2FB8bFF1Da1CE36babAFA28ee2d1C526b66, 75000, month);
        setInitialDistribution(0xeb1eF2FB8bFF1Da1CE36babAFA28ee2d1C526b66, 75000, 2*month);
        setInitialDistribution(0xeb1eF2FB8bFF1Da1CE36babAFA28ee2d1C526b66, 75000, 3*month);

        setInitialDistribution(0x76395534473E8b5aB5A0003687cfaa44369042A4, 75000, month);
        setInitialDistribution(0x76395534473E8b5aB5A0003687cfaa44369042A4, 75000, 2*month);
        setInitialDistribution(0x76395534473E8b5aB5A0003687cfaa44369042A4, 75000, 3*month);

        setInitialDistribution(0x0Ca1940D2Dc73c1F242FBbB17E5e45ED8356e060, 75000, month);
        setInitialDistribution(0x0Ca1940D2Dc73c1F242FBbB17E5e45ED8356e060, 75000, 2*month);
        setInitialDistribution(0x0Ca1940D2Dc73c1F242FBbB17E5e45ED8356e060, 75000, 3*month);

        setInitialDistribution(0x4Cc3e7ab0c7D0FF20082E3793Bb690C6a48527d7, 100000, month);
        setInitialDistribution(0x4Cc3e7ab0c7D0FF20082E3793Bb690C6a48527d7, 100000, 2*month);
        setInitialDistribution(0x4Cc3e7ab0c7D0FF20082E3793Bb690C6a48527d7, 100000, 3*month);
        
        setInitialDistribution(0x7716fE433A772aF770eeb53eeDAF65EC0cac6D31, 100000, month);
        setInitialDistribution(0x7716fE433A772aF770eeb53eeDAF65EC0cac6D31, 100000, 2*month);
        setInitialDistribution(0x7716fE433A772aF770eeb53eeDAF65EC0cac6D31, 100000, 3*month);

        setInitialDistribution(0x562cBA8b9Cbd8a1151F91304A4097bb878A2dbd1, 100000, month);
        setInitialDistribution(0x562cBA8b9Cbd8a1151F91304A4097bb878A2dbd1, 100000, 2*month);
        setInitialDistribution(0x562cBA8b9Cbd8a1151F91304A4097bb878A2dbd1, 100000, 3*month);

        setInitialDistribution(0xfA3a5bE62eeef1bc6FEffd7F68D4A186cC916fb1, 100000, month);
        setInitialDistribution(0xfA3a5bE62eeef1bc6FEffd7F68D4A186cC916fb1, 100000, 2*month);
        setInitialDistribution(0xfA3a5bE62eeef1bc6FEffd7F68D4A186cC916fb1, 100000, 3*month);

        setInitialDistribution(0xf7E141D70faC9584d4dDCD8978354293cBE0dbb3, 100000, month);
        setInitialDistribution(0xf7E141D70faC9584d4dDCD8978354293cBE0dbb3, 100000, 2*month);
        setInitialDistribution(0xf7E141D70faC9584d4dDCD8978354293cBE0dbb3, 100000, 3*month);

        setInitialDistribution(0x110286CEcDAC1714709F2DA76657Bf9F0EBC8Cb3, 100000, month);
        setInitialDistribution(0x110286CEcDAC1714709F2DA76657Bf9F0EBC8Cb3, 100000, 2*month);
        setInitialDistribution(0x110286CEcDAC1714709F2DA76657Bf9F0EBC8Cb3, 100000, 3*month);

        setInitialDistribution(0xC349a93dccA23C12B2891B7beB7213185437B972, 100000, month);
        setInitialDistribution(0xC349a93dccA23C12B2891B7beB7213185437B972, 100000, 2*month);
        setInitialDistribution(0xC349a93dccA23C12B2891B7beB7213185437B972, 100000, 3*month);

        setInitialDistribution(0xA256154DAaAf77993748E51909724B6dBE20b76b, 100000, month);
        setInitialDistribution(0xA256154DAaAf77993748E51909724B6dBE20b76b, 100000, 2*month);
        setInitialDistribution(0xA256154DAaAf77993748E51909724B6dBE20b76b, 100000, 3*month);

        setInitialDistribution(0x02F90013c14fcE45a3632d475aDF762D99987Dc9, 100000, month);
        setInitialDistribution(0x02F90013c14fcE45a3632d475aDF762D99987Dc9, 100000, 2*month);
        setInitialDistribution(0x02F90013c14fcE45a3632d475aDF762D99987Dc9, 100000, 3*month);

        setInitialDistribution(0x19a4035f71CDE3f692F228Ec8Ba919c03694cb64, 100000, month);
        setInitialDistribution(0x19a4035f71CDE3f692F228Ec8Ba919c03694cb64, 100000, 2*month);
        setInitialDistribution(0x19a4035f71CDE3f692F228Ec8Ba919c03694cb64, 100000, 3*month);

        setInitialDistribution(0xf6BBFcB7107d9D9C556559B5d408aa49cfC90c02, 100000, month);
        setInitialDistribution(0xf6BBFcB7107d9D9C556559B5d408aa49cfC90c02, 100000, 2*month);
        setInitialDistribution(0xf6BBFcB7107d9D9C556559B5d408aa49cfC90c02, 100000, 3*month);

        setInitialDistribution(0xa1CF4F575533ae18F1c747b66845Ea9F935BECB9, 100000, month);
        setInitialDistribution(0xa1CF4F575533ae18F1c747b66845Ea9F935BECB9, 100000, 2*month);
        setInitialDistribution(0xa1CF4F575533ae18F1c747b66845Ea9F935BECB9, 100000, 3*month);

        setInitialDistribution(0x9A4FFeE0b84E230dE9377EFeF3b6454dF9c8CC8A, 100000, month);
        setInitialDistribution(0x9A4FFeE0b84E230dE9377EFeF3b6454dF9c8CC8A, 100000, 2*month);
        setInitialDistribution(0x9A4FFeE0b84E230dE9377EFeF3b6454dF9c8CC8A, 100000, 3*month);

        setInitialDistribution(0xdbA62CaBD38F68ed7936D561b17d5b2f0D05d201, 100000, month);
        setInitialDistribution(0xdbA62CaBD38F68ed7936D561b17d5b2f0D05d201, 100000, 2*month);
        setInitialDistribution(0xdbA62CaBD38F68ed7936D561b17d5b2f0D05d201, 100000, 3*month);

        setInitialDistribution(0x3c4236483391976B86D4EFc0388494FbE959c0F1, 100000, month);
        setInitialDistribution(0x3c4236483391976B86D4EFc0388494FbE959c0F1, 100000, 2*month);
        setInitialDistribution(0x3c4236483391976B86D4EFc0388494FbE959c0F1, 100000, 3*month);

    }

    function setTokenAddress(address _tokenAddress) external onlyOwner whenNotPaused  {
        erc20 = ERC20(_tokenAddress);
    }
    
    function safeGuardAllTokens(address _address) external onlyOwner whenPaused  { /* In case of needed urgency for the sake of contract bug */
        require(erc20.transfer(_address, erc20.balanceOf(address(this))));
    }

    function setTGEDate(uint256 _time) external onlyOwner whenNotPaused  {
        TGEDate = _time;
    }

    /**
    *   Should allow any address to trigger it, but since the calls are atomic it should do only once per day
     */

    function triggerTokenSend() external whenNotPaused  {
        /* Require TGE Date already been set */
        require(TGEDate != 0, "TGE date not set yet");
        /* TGE has not started */
        require(block.timestamp > TGEDate, "TGE still hasn´t started");
        /* Test that the call be only done once per day */
        require(block.timestamp.sub(lastDateDistribution) > 1 days, "Can only be called once a day");
        lastDateDistribution = block.timestamp;
        /* Go thru all tokenOwners */
        for(uint i = 0; i < tokenOwners.length; i++) {
            /* Get Address Distribution */
            DistributionStep[] memory d = distributions[tokenOwners[i]];
            /* Go thru all distributions array */
            for(uint j = 0; j < d.length; j++){
                if( (block.timestamp.sub(TGEDate) > d[j].unlockDay) /* Verify if unlockDay has passed */
                    && (d[j].currentAllocated > 0) /* Verify if currentAllocated > 0, so that address has tokens to be sent still */
                ){
                    uint256 sendingAmount;
                    sendingAmount = d[j].currentAllocated;
                    distributions[tokenOwners[i]][j].currentAllocated = distributions[tokenOwners[i]][j].currentAllocated.sub(sendingAmount);
                    distributions[tokenOwners[i]][j].amountSent = distributions[tokenOwners[i]][j].amountSent.add(sendingAmount);
                    require(erc20.transfer(tokenOwners[i], sendingAmount));
                }
            }
        }   
    }

    function setInitialDistribution(address _address, uint256 _tokenAmount, uint256 _unlockDays) internal onlyOwner whenNotPaused {
        /* Add tokenOwner to Eachable Mapping */
        bool isAddressPresent = false;

        /* Verify if tokenOwner was already added */
        for(uint i = 0; i < tokenOwners.length; i++) {
            if(tokenOwners[i] == _address){
                isAddressPresent = true;
            }
        }
        /* Create DistributionStep Object */
        DistributionStep memory distributionStep = DistributionStep(_tokenAmount * decimals, _tokenAmount * decimals, _unlockDays, 0);
        /* Attach */
        distributions[_address].push(distributionStep);

        /* If Address not present in array of iterable token owners */
        if(!isAddressPresent){
            tokenOwners.push(_address);
        }
    }
}