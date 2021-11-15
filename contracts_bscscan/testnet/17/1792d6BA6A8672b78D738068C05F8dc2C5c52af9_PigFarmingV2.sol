// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

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
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



 
interface FarmLandNFT {
 
    function tokenMoreDatas(uint256) external view returns (uint256);
    function transferFrom(address, address, uint) external ;
    function ownerOf(uint256) external view returns (address);
 
}
 
interface FarmTokens {
    
    function mint(address to, uint256 amount) external  ;
 
    function burn(uint256 amount) external ;
     
    function transferFrom(address, address, uint) external returns (bool);

    function transfer(address, uint) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

interface Token {
 
    function transferFrom(address, address, uint) external returns (bool);

    function transfer(address, uint) external returns (bool);
}
 
 interface IPancake {
          function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}
 

contract PigFarmingV2 is Ownable {
    using SafeMath for uint256;
     
 

    // Info of each user.
    struct UserInfo {
        uint256 sow; // Number of Sow in Farms.
        uint256 boar; // Number of Sow in Farms.
        uint256 food; // Food Quantity.
        uint256 farmId; // Token ID for FarmLand NFT.
        uint256 depositTime; // User's last deposit time.
        uint256 claimTime; // User's last claim time. 
        uint256 lockDays; // User's last claim time. 
        bool landlocked; // Has user locked land to the contract
    }

     

    // The sow and boar token
    FarmTokens public sowToken;
    FarmTokens public boarToken;

    // The piglet token
    FarmTokens public pigletToken;

    // The food token
    FarmTokens public foodToken;
    
    // farm Land Contract.
    FarmLandNFT public farmLand;

    // Piglet mature time.
    uint256 public pigsMatureTime = 7;

    // Food used by chicken per day.
    uint256 public foodPerDay = 20;

    uint256 public perBoarSow = 10;

    // Keep track of number of pigs stored 
    uint256 public totalSow = 0;


    uint256 public dayInterval = 86400;
    uint256 public foodInterval = 86400;


    // Base Token
    address public baseToken;

    // Router
    address public router =  0x10ED43C718714eb63d5aA57B78B54704E256024E ; 
    address public pairToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 ;
  
    bool public mintAllowed = false;


    uint256 public perPigArea = 10;

    

    // Fees
    uint256 public farmFee = 15;
    uint256 public unfarmFee = 25;
    address public feeTaker = 0x36b219Fe9218DD0e94B2D67dF7562e2fCACcF445;
    address public authorized ;

    mapping (address => UserInfo) public userInfo;
   


    event Deposit(address indexed user, uint256 amount);
    event Removed(address indexed user,uint256 amount);
    event Claim(address indexed user, uint256 amount);
   
     constructor (
        FarmTokens _pigletToken,
        FarmTokens _sowToken,  
        FarmTokens _boarToken,  
        FarmTokens _foodToken,  
        FarmLandNFT _farmLand,
        address _baseToken
    )  {
        pigletToken = _pigletToken;
        sowToken = _sowToken;
        boarToken = _boarToken;
        baseToken = _baseToken ;
        farmLand = _farmLand;
        foodToken = _foodToken;
    } 
    
     

    // Check Farm Land is Free.
    function landIsfree(uint256 _tokenId , address _user) public view returns (bool)  {
            UserInfo storage user = userInfo[_user];
            return(user.sow == 0 && user.boar == 0 && user.farmId == _tokenId && user.landlocked) ;
    }

    // Reset User .
    function resetUser(address _user) public    {
            require((msg.sender == authorized || msg.sender == owner()), "not authorized");
            UserInfo storage user = userInfo[_user];
            user.sow = 0 ;
            user.boar = 0 ;
            user.farmId = 0 ;
            user.landlocked = false ;
            user.depositTime = 0 ;
            user.claimTime = 0 ;
            user.food = 0 ;
            user.lockDays = 0 ;
    }
    

    // Check and Transfer ownership of Farm Land.
    function checkAndTransferLand(address _user, uint256 _farmId) public  {
            UserInfo storage user = userInfo[_user];
            require(user.landlocked == false, "Already Locked");
            farmLand.transferFrom(_user,address(this),_farmId );
            user.farmId = _farmId ;
            user.landlocked = true ;
    }

    // Return if Farm Land is user's asset.
    function checkFarmLandAvailability(address _user, uint256 _farmId) public view returns (bool) {
            UserInfo storage user = userInfo[_user];
            uint256 _tokenId = user.farmId;
            return (_tokenId == _farmId );
    }

      // Return user's Farm Land asset.
    function getUserToken(address _user) public view returns (address,uint256,uint256,uint256,bool) {
            UserInfo storage user = userInfo[_user];
            uint256 _tokenId = user.farmId;
            bool locked = user.landlocked;            
            address _owner =  farmLand.ownerOf(_tokenId) ;
            (uint256 _area, uint256 _chickencapacity) = getFarmLandCapacity(_tokenId) ;
            return (_owner, _tokenId,_area,_chickencapacity,locked);
    }

     // Return Farm Land capacity.
    function getFarmLandCapacity(uint256 _tokenId) public view returns (uint256,uint256) {            
            uint256 _capacity = farmLand.tokenMoreDatas(_tokenId);
            uint256 _chickenCapacity =  _capacity.div(perPigArea);
            return (_capacity , _chickenCapacity) ;
    }
      // Return if Farm Land is enough for given chicken.
    function checkFarmLandCapacity(uint256 _pigs, address _user) public view returns (bool) {
            UserInfo storage user = userInfo[_user];
            uint256 _tokenId = user.farmId;
            uint256 _capacity = farmLand.tokenMoreDatas(_tokenId);
            uint256 _reqCapacity =  _pigs.mul(perPigArea);
            return (_reqCapacity <= _capacity) ;
    }

    

    // View function to see pending Piglets on frontend.
    function pendingPiglets(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _startTime = user.claimTime;
        uint256 _piglets = 0 ;
        if (user.claimTime == 0 ) {
            _startTime = user.depositTime ;
        }

        uint256 daysDifference = block.timestamp.sub(_startTime).div(dayInterval);
        uint256 multiple = daysDifference.div(pigsMatureTime) ;
        if(user.sow > 0){
        uint256 totalPigs = user.sow.add(user.boar) ;
        uint256 _totalSpan = getPigSpan(totalPigs,user.food);
        uint256 _userSow = user.sow ;
        if(daysDifference > 0 ){
            if(daysDifference >= _totalSpan){
            multiple = _totalSpan.div(pigsMatureTime) ;
            _piglets = multiple.mul(_userSow) ;                
            }
            else{
            _piglets = multiple.mul(_userSow) ;                

            }
        } 
        }
      
        return _piglets;
    }

 


    // View function to see user's sow on frontend.
    function getUserSow(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _sow =  user.sow ;
        return _sow;
    }

    // View function to see user's sow on frontend.
    function getUserBoar(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _boar =  user.boar ;
        return _boar;
    }

    // View function to see pigs span as per food on frontend.
    function getPigSpan(uint256 _pigs,uint256 _food) public view returns (uint256) {        
        return (_food.div(_pigs.mul(foodPerDay)) );
    }

    // View function to see pigs span as per food on frontend.
    function getNextClaim(address _user) public view returns (uint256,uint256) {    
        UserInfo storage user = userInfo[_user];
        uint256 _pigs = user.sow.add(user.boar) ;
        uint256 _food = user.food ;
        uint256 _totalDays = _food.div(_pigs.mul(foodPerDay)) ;
        uint256 _startTime = user.claimTime ;
        if(user.claimTime == 0){
            _startTime = user.depositTime ;
        }
        uint256 _endTime = _startTime.add(dayInterval.mul(_totalDays)) ;
        uint256 _lastDifference = block.timestamp.sub(_startTime);
       
        uint256 _blockDivide = _lastDifference.div(pigsMatureTime.mul(dayInterval)) ;
        uint256 _nextTime = _startTime.add(_blockDivide.add(1).mul(dayInterval)) ;
 
        return (_endTime,_nextTime);
    }

    function getRequiredBoar(uint256 _sow) public view returns (uint256) {
        

        uint256 requiredBoar = _sow.div(perBoarSow) ;
        uint256 nearestMultiple = requiredBoar.div(1e18) ;
        if(nearestMultiple == 0){
            requiredBoar = 1e18 ;
        }
        else if(requiredBoar > nearestMultiple.mul(1e18)){
            requiredBoar = nearestMultiple.add(1).mul(1e18) ;            
        }
        else if(requiredBoar == nearestMultiple.mul(1e18)){
            requiredBoar = nearestMultiple.mul(1e18) ;                                   
        }

        return requiredBoar ;
    }



    // Store chicken in farm
     function deposit(uint256 _farmId,uint256 _sow, uint256 _boar, uint256 _days ) public {
        UserInfo storage user = userInfo[msg.sender];

        require(user.sow ==  0 , "Already Deposited, use deposit more" );

        _claimPiglets(msg.sender);
        uint _totalAccPigs = user.sow.add(_sow);
        _totalAccPigs = _totalAccPigs.add(user.boar.add(_boar));
        uint _requiredFood =  _totalAccPigs*_days*foodPerDay ;

        uint256 requiredBoar = getRequiredBoar(user.sow.add(_sow))  ;
       

        bool crossCheck =  (user.boar.add(_boar) >= requiredBoar ); 

        require(_sow > 0 , "Not enough sow to store" );
        require(crossCheck == true , "Not enough boar to store" );
        require(_days > 0 , "Not enough days to store" );

        require(checkFarmLandAvailability(address(msg.sender),_farmId) , "farm Land not authorized." );

        require(checkFarmLandCapacity(_totalAccPigs, msg.sender) , "Farm Land doesn't have enough capacity" );

        require(_days > 0 , "Not enough days to store" );

        uint256 _fee = getDepositFee(_sow.add(_boar)) ;
        if(_fee > 0 ){
        Token(baseToken).transferFrom(address(msg.sender), feeTaker, _fee);
        }
         
        sowToken.transferFrom(address(msg.sender), address(this), _sow);
        if(_boar > 0){
        boarToken.transferFrom(address(msg.sender), address(this), _boar);
        }
        foodToken.transferFrom(address(msg.sender), address(this), _requiredFood);

        user.lockDays = _days ;
        user.sow = user.sow.add(_sow);
        user.boar = user.boar.add(_boar);
        user.food = user.food.add(_requiredFood);
        user.depositTime = block.timestamp ;
        
        emit Deposit(msg.sender, _sow);
        emit Deposit(msg.sender, _boar);
    }

 

    // Store more sow in farm
     function depositMoreSow(uint256 _sow , uint256 _farmId) public {
        UserInfo storage user = userInfo[msg.sender];

        require(user.sow >  0 , "Not Deposited, use deposit" ); 
        
        uint256 requiredBoar = getRequiredBoar(user.sow.add(_sow))  ;     
        uint256 missingBoar =  requiredBoar - user.boar ;

        boarToken.transferFrom(address(msg.sender), address(this), missingBoar);
        user.boar = user.boar.add(missingBoar);
        bool crossCheck =  (user.boar >= requiredBoar ); 

        require(crossCheck == true , "Not enough boar to store, Please add boar" );

        require(getUnlockTime(msg.sender) >  block.timestamp , "Time Up, please add feed first" ); 

        _claimPiglets(msg.sender);

        uint256 remainingDays = getPigSpan(user.sow.add(user.boar), user.food);
        uint256 _totalAccPig = user.sow.add(user.boar.add(_sow)) ;
        uint _requiredFood =  _sow*remainingDays*foodPerDay ;
        require(_sow > 0 , "Not enough sow to store" );
      
        require(checkFarmLandAvailability(address(msg.sender),_farmId) , "farm Land not authorized." );

        require(checkFarmLandCapacity(_totalAccPig, msg.sender) , "Farm Land doesn't have enough capacity" );

        uint256 _fee = getDepositFee(_sow) ;
        if(_fee > 0 ){
        Token(baseToken).transferFrom(address(msg.sender), feeTaker, _fee);
        }
         
        sowToken.transferFrom(address(msg.sender), address(this), _sow);
        foodToken.transferFrom(address(msg.sender), address(this), _requiredFood);

      
        user.sow = user.sow.add(_sow);
        user.food = user.food.add(_requiredFood);
        
        emit Deposit(msg.sender, _sow);
    }

    // Transfer Piglets 
    function _transferPiglets(address _user, uint256 _piglets ) internal {
         if(mintAllowed){
            pigletToken.mint(address(this), _piglets);
            }
            pigletToken.transfer(_user, _piglets); 

    }

    // Claim Piglets Public
    function claimPiglets() public {
            _claimPiglets(msg.sender);                
    }

    // Claim Piglets Internal
    function _claimPiglets(address _user) internal {
            uint _piglets = pendingPiglets(_user);   
            if(_piglets > 0){
            UserInfo storage user = userInfo[_user];    
            checkandBurnoldPigFood(_user) ;
            user.claimTime = block.timestamp ;                     
            _transferPiglets(_user,_piglets);            
            emit Claim(_user, _piglets);
            }

            
    }

    // check and burn dfood 
    function checkandBurnoldPigFood(address _user) internal {
        // uint256 _chicekenAlive = getUserSow(_user) ;
            UserInfo storage user = userInfo[_user];    
            uint256 _startTime = user.claimTime ;
            if(user.claimTime == 0 ){
                _startTime = user.depositTime ;
            }
            uint256 daysDifference = block.timestamp.sub(_startTime).div(foodInterval);
            uint256 _usedFood = user.sow.add(user.boar).mul(foodPerDay).mul(daysDifference);
            if(_usedFood > user.food){
            _burnFood(user.food);
            user.food = 0 ;
            }
            else{
            _burnFood(_usedFood);
            user.food = user.food.sub(_usedFood) ;

            }
 


    }

    // get base price 
     function getBaseTokenPrice() public  view returns (uint256) {
        address[] memory  pair = new address[](2) ;
        pair[0] = pairToken ;
        pair[1] = baseToken ;
        uint[] memory _token = IPancake(router).getAmountsOut(1e18, pair);
        return _token[1] ;
        // uint256 price = 1e18 ;
        // return  price; 
    }


    // Get Deposit Fee 

    function getDepositFee(uint256 _pigs) public view returns (uint256) {
        uint256 _fee = farmFee.mul(getBaseTokenPrice());
        _fee = _fee.mul(_pigs).div(1e18) ;
        return _fee ;           
    }


    // Get Remove Fee 

    function getRemoveFee(uint256 _pigs) public view returns (uint256) {
        uint256 _fee = unfarmFee.mul(getBaseTokenPrice());
        _fee = _fee.mul(_pigs).div(1e18) ;
        return _fee ;           
    }



    // Burn Food 
    function _burnFood(uint _food) internal {          
            foodToken.burn(_food);                                
    }

    // Transfer Sow 
    function _transferSow(address _user, uint256 _sow ) internal {
            sowToken.transfer(_user,_sow);
    }

    // Transfer Boar 
    function _transferBoar(address _user, uint256 _boar ) internal {
            boarToken.transfer(_user,_boar);
    }

    // Get UnlockTime  Time
    function getUnlockTime(address _user) public view returns(uint256) {
            UserInfo storage user = userInfo[_user];    
            return (user.depositTime.add(user.lockDays.mul(foodInterval))) ;
    }
 
    // Add more Days of farming
    function addMoreDays(uint256 _days) public  {
            _claimPiglets(msg.sender); 
            UserInfo storage user = userInfo[msg.sender];  
            require(user.sow > 0 , "No sow to Feed") ;
            uint256 _pigs = user.sow.add(user.boar) ;
            uint256 _requiredFood = _pigs.mul(foodPerDay).mul(_days);
            if(block.timestamp > getUnlockTime(msg.sender) ){
                user.depositTime = block.timestamp ;
                user.claimTime = block.timestamp ;
                user.lockDays = _days ;  
            }
            else{
               user.lockDays = user.lockDays.add(_days) ;  

            }
            foodToken.transferFrom(msg.sender, address(this), _requiredFood);            
            user.food = user.food.add(_requiredFood) ;
           
           
             
    }

    // Remove Sow 
    function removeSow(uint256 _sow) public {
            _claimPiglets(msg.sender) ;       
            UserInfo storage user = userInfo[msg.sender];    
            require(user.sow >= _sow, "Not Enough Sow to Remove");
            require(block.timestamp >= getUnlockTime(msg.sender), "Can't remove before unlock time");
            
 
            uint256 _fee = getRemoveFee(_sow); 
            if(_fee > 0 ){
                   Token(baseToken).transferFrom(address(msg.sender), feeTaker, _fee);
            }
 
            user.claimTime = block.timestamp ;
            
            _transferSow(msg.sender,_sow);
          
            uint256 _finalSow = user.sow.sub(_sow) ;
            
            uint256 requiredBoar =  getRequiredBoar(_finalSow) ;
            
            if(_finalSow == 0){
                requiredBoar = 0 ; 
            }
            
            uint256 extraBoar = user.boar.sub(requiredBoar) ;
            _transferBoar(msg.sender,extraBoar);
            user.boar = user.boar.sub(extraBoar) ;
            user.sow = user.sow.sub(_sow) ;

            emit Removed(msg.sender, _sow);


    }


     
   
 
    function pigletBalance() public view returns (uint256) {
        return pigletToken.balanceOf(address(this));
    }

   
    /* Admin Functions */

 
    /// @param _sow; // Number of Sow in Farms.
    /// @param _boar; // Number of Sow in Farms.
    /// @param _food; // Food Quantity.
    /// @param _farmId; // Token ID for FarmLand NFT.
    /// @param _depositTime; // User's last deposit time.
    /// @param _claimTime; // User's last claim time. 
    /// @param _lockDays; // User's last claim time. 
    /// @param _landlocked; // Has user locked land to the contract
    function addData(uint256 _sow ,uint256 _boar ,uint256  _food ,uint256  _farmId ,uint256  _depositTime,uint256  _claimTime , uint256 _lockDays , bool _landlocked,address _user)  external onlyOwner  {
            UserInfo storage user = userInfo[_user];    
            user.sow = _sow ;
            user.boar = _boar ;
            user.food = _food ;
            user.farmId = _farmId ;
            user.depositTime = _depositTime ;
            user.claimTime = _claimTime ;
            user.lockDays = _lockDays ;
            user.landlocked = _landlocked ;
    }


    /// @param _allowed allowed
    function setMintAllowed(bool _allowed)  external onlyOwner  {
       mintAllowed = _allowed ;
    }


    /// @param  _baseToken The Base token
    function setBaseToken(address _baseToken) external onlyOwner {
        baseToken = _baseToken;
    }


    /// @param _fee value of farmFee
    function setFarmFee(uint256 _fee)  external onlyOwner  {
       farmFee = _fee ;
    }

    /// @param _fee value of unfarmFee
    function setunfarmFee(uint256 _fee)  external onlyOwner  {
       unfarmFee = _fee ;
    }

    /// @param _dayInterval value of dayInterval
    function setDayInterval(uint256 _dayInterval)  external onlyOwner  {
       dayInterval = _dayInterval ;
    }

    /// @param _foodInterval value of unfarmFee
    function setFoodInterval(uint256 _foodInterval)  external onlyOwner  {
       foodInterval = _foodInterval ;
    }

    
    /// @param _authorized authorize to reset
    function setauthorized(address _authorized)  external onlyOwner  {
       authorized = _authorized ;
    }


    /// @param _feeTaker address of feeTaker
    function setFeeTaker(address  _feeTaker)  external onlyOwner  {
       feeTaker = _feeTaker ;
    }

    /// @param _pigsMatureTime The amount of time piglets take to mature
    function setPigsMatureTime(uint256 _pigsMatureTime) external onlyOwner {
        pigsMatureTime = _pigsMatureTime;
    }

    /// @param  _boarToken The Boar token
    function setBoarToken(FarmTokens _boarToken) external onlyOwner {
        boarToken = _boarToken;
    }

    /// @param  _sowToken The Sow token
    function setSowToken(FarmTokens _sowToken) external onlyOwner {
        sowToken = _sowToken;
    }


     /// @param  _pigletToken The piglet token
    function setPigletToken(FarmTokens _pigletToken) external onlyOwner {
        pigletToken = _pigletToken;
    }

    /// @param  _foodToken The food token
    function setFoodToken(FarmTokens _foodToken) external onlyOwner {
        foodToken = _foodToken;
    }

    /// @param  _foodPerDay The pig food per day
    function setFoodPerDay(uint256 _foodPerDay) external onlyOwner {
        foodPerDay = _foodPerDay;
    }

    /// @param  _perBoarSow Sow per boar
    function setSowPerBoar(uint256 _perBoarSow) external onlyOwner {
        perBoarSow = _perBoarSow;
    }

    /// @param  _perPigArea The area per pig
    function setAreaPerPig(uint256 _perPigArea) external onlyOwner {
        perPigArea = _perPigArea;
    }

       /// @param  _farmLand The area per chicken
    function setFarmLand(FarmLandNFT _farmLand) external onlyOwner {
        farmLand = _farmLand;
    }

    /// @dev Obtain the sow token balance
    function getTotalSow() public view returns (uint256) {
          return sowToken.balanceOf(address(this));
    }
 
    /// @dev Obtain the boar token balance
    function getTotalBoar() public view returns (uint256) {
          return boarToken.balanceOf(address(this));
    }


    function transferAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {        
        Token(_tokenAddr).transfer(_to, _amount);
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

