/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

/**
                                                                                                                                                       
                                 ++++++++        *****.        +****      =***    +++++++++++       *****=            ****      *****    =***          
                                 *@@@@@@@%       #@@@@%         @@@@%      @@#   #@@@@@@@@@@%       *@@@@@         #@@@@@@@@     @@@@#   :@@*          
                      *    *     *@@@%   -       @@@@@@=        %@@@@%     %@#   .  :@@@@:  +       %@@@@@*       #@@@#    -     :@@@@+  %@%           
                     +:    *     *@@@%          *@@#@@@%        %@@@@@@    %@#       @@@@          [email protected]@#@@@@       %@@@%           *@@@@.*@@            
                     =:    -=    *@@@%          @@* @@@@*       %@%@@@@@   %@#       @@@@          %@# %@@@#      *@@@@@%          %@@@@@@             
                    *-.    =:    *@@@@@@#      *@@  *@@@@       %@#=%@@@@  %@#       @@@@         [email protected]@  [email protected]@@@       [email protected]@@@@@@%        %@@@@*             
        *- *        *=.    +-=   *@@@%  +      @@%###@@@@*      %@#  %@@@@*%@#       @@@@         %@@###@@@@#         %@@@@@@       [email protected]@@@              
      #=   ###   %#=*=     +=+   *@@@%        *@@%%%%%@@@@      %@#   #@@@@@@#       @@@@        [email protected]@%%%%%@@@@           [email protected]@@@#      [email protected]@@%              
    ##+     #   :%#*#+---- *+    *@@@%        @@*     %@@@#     %@#    #@@@@@*       @@@@        %@#     %@@@%           #@@@#      [email protected]@@%              
    ##           #*#**+=---.+    *@@@%       *@@      [email protected]@@@     %@#     *@@@@*       @@@@       *@@      [email protected]@@@    %%*   *@@@%       [email protected]@@@              
   ##*            **==++==++     #@@@@      [email protected]@@      *@@@@%    @@@       *@@*      [email protected]@@@#      @@@      [email protected]@@@@   +%@@@@@@%.        #@@@@=             
   ##*           #***-=++--:                                                                                                                           
   ###+           +=+==+**                                                                                                                             
    %##       %#  =:-++**+                        %@@@@+        *@@@@@@@@%:      #@@@@@@@@     @@@@#      %@@        #@@@@%                            
     %%#     #%* .=..*+=+-:                       %@@@@@        [email protected]@@@*#@@@@#     [email protected]@@@***%     *@@@@%     *@%        #@@@@@                            
      #%#*   %%#*=*:+**+=--                      [email protected]@@@@@*       [email protected]@@@  [email protected]@@@     [email protected]@@@         *@@@@@%    *@%        @@%@@@%                           
        ####*%%#***+     *+                      @@*[email protected]@@@       [email protected]@@@  [email protected]@@%     [email protected]@@@         *@@@@@@%   *@%       #@%[email protected]@@@=                          
               %##                              *@%  %@@@#      [email protected]@@@  %@@%      [email protected]@@@%%%      *@@[email protected]@@@@  *@%       @@  *@@@%                          
               %%#                              @@#  #@@@@      [email protected]@@@%@@@*       [email protected]@@@##%      *@@  %@@@@+*@%      #@%  [email protected]@@@+                         
                ##*                            *@@@@@@@@@@#     [email protected]@@@*@@@@       [email protected]@@@         *@@   %@@@@%@%      @@@@@@@@@@@                         
                #                              @@*    [email protected]@@@     [email protected]@@@-#@@@@      [email protected]@@@         *@@    %@@@@@%     #@%     @@@@*                        
                %                             *@@      %@@@%    [email protected]@@@  %@@@%     [email protected]@@@     +   *@@     #@@@@%    [email protected]@:     *@@@@                        
                                              @@#      *@@@@=   [email protected]@@@   %@@@%    *@@@@@@@@@*   #@@      :%@@%    %@@      [email protected]@@@#                       
                                                                          #:                               *#                                          
                                                                                                                                                       

*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FantasyArenaPrivateSale {
    using SafeMath for uint256;
        
    IERC721 private fasyNft;
    IERC20 private fapToken;
    IERC20 private BUSD;
    
    address public owner;
    bool public enabled;
    uint256 public fapPerBusd;
    uint256 public maxPurchase;
    uint256 public minPurchase;
    mapping (address => bool) public whitelist;
    mapping (address => uint256) public purchased;
    mapping (address => bool) public noLimit;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "no permissions");
        _;
    }
    
    modifier onWhitelist() {
        require(fasyNft.balanceOf(msg.sender) > 0 || whitelist[msg.sender], "this address is not on the whitelist");
        _;
    }
    
    modifier isEnabled() {
        require(enabled, "sale not enabled");
        _;
    }
    
    constructor() {
        fapToken = IERC20(0x49EcC942978bDAfF543bc0332Fd91d669E80430F);
        fasyNft = IERC721(0xd3B15482f686113bb48c957f068b9935590b6daD);
        BUSD = IERC20(0xc880D1FA2AcFD2acAb04B8F34Cf0af5Ca2Fc19B6);
        owner = msg.sender;
        fapPerBusd = 100;
        maxPurchase = 500 * 10 ** 18;
        minPurchase = 20 * 10 ** 18;
    }
    
    function userStatus() public view returns (
            bool saleEnabled,
            bool whitelisted, 
            uint256 alreadyPurchased,
            uint256 remaining,
            uint256 contractBalance,
            uint256 fapPrice,
            address busdAddress,
            uint256 busdApproved
        ) {
        saleEnabled = enabled;
        whitelisted = fasyNft.balanceOf(msg.sender) > 0 || whitelist[msg.sender];
        alreadyPurchased = purchased[msg.sender];
        contractBalance = fapToken.balanceOf(address(this));
        fapPrice = fapPerBusd;
        busdAddress = address(BUSD);
        busdApproved = BUSD.allowance(msg.sender, address(this));
        if (noLimit[msg.sender]) {
            remaining = contractBalance;
        } else if (whitelisted == false) {
            remaining = 0;
        } else {
            remaining = maxPurchase.sub(purchased[msg.sender]);  
        }
    }
    
    function exchange(uint256 amountBusd) public onWhitelist isEnabled {
        uint256 receivedFap= amountBusd.mul(fapPerBusd);
        require(BUSD.transferFrom(msg.sender, address(this), amountBusd), "could not transfer BUSD");
        require(fapToken.balanceOf(address(this)) >= receivedFap, "not enough tokens left");
        uint256 p = purchased[msg.sender].add(receivedFap);
        if (noLimit[msg.sender] == false) {
            require(p <= maxPurchase, "you cannot purchase this many tokens");
        }
        require(p >= minPurchase, "minimum spend not met");
        purchased[msg.sender] = p;
        fapToken.transfer(msg.sender, receivedFap);
    }
    
    // Admin methods
    function changeOwner(address who) public onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }
    
    function configure(uint256 _fapPerBusd, uint256 _minPurchase, uint256 _maxPurchase) public onlyOwner {
        fapPerBusd = _fapPerBusd;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }
    
    function enableSale(bool enable) public onlyOwner {
        enabled = enable;
    }
    
    function removeBnb() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    function transferTokens(address token, address to) public onlyOwner returns(bool){
        uint256 balance = IERC20(token).balanceOf(address(this));
        return IERC20(token).transfer(to, balance);
    }
    
    function editWalletLimit(address who, bool hasNoLimit) public onlyOwner {
        noLimit[who] = hasNoLimit;
    }
    
    function editWhitelist(address who, bool whitelisted) public onlyOwner {
        whitelist[who] = whitelisted;
    }
    
    function bulkAddWhitelist(address[] memory people) public onlyOwner {
        for (uint256 i = 0; i < people.length; i++) {
            editWhitelist(people[i], true);
        }
    }
}