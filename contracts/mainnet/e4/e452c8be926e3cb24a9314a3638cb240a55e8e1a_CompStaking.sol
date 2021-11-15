// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25;
abstract contract  IComp {
    mapping (uint256 => string) public geneMap;
    function ownerOf(uint256 tokenId) external view virtual returns (address owner);
    uint256  public tokenId;
}
abstract contract IERC20{
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
    function balanceOf(address account) external view  virtual returns (uint256);
}
contract CompStaking {

    struct PoolInfo{
        uint32 startRedeemTokenId; // 2000
        address poolTokenContract; //
        uint32  initStakingRatio; //10
        uint32  onceCompReward; //20
        address initOwner;
        uint32 totalPower;
    }

    uint32 private _syncTokenId=0;

    mapping (address => mapping(uint32=>uint256) ) public compStakingMap;
    mapping (address => PoolInfo ) public pools;

    uint8[][] public standTemplates=
    [
    [5,9,10,10,1,7,3,0,0],
    [5,9,10,3,10,1,0,0,0],
    [5,9,10,3,10,1,0,0,0],
    [5,8,5,10,3,4,1,0,0],
    [5,9,10,3,1,0,0,0,0],
    [5,9,3,10,1,4,0,0,0],
    [5,9,10,10,1,0,0,0,0],
    [5,8,5,10,1,3,0,0,0],
    [5,9,3,10,2,1,0,0,0],
    [5,9,3,10,5,1,0,0,0],
    [5,9,10,3,10,1,2,0,0],
    [5,9,10,10,3,1,0,0,0],
    [5,9,3,10,1,10,0,0,0],
    [5,9,10,10,1,10,10,5,0],
    [5,9,10,10,4,2,1,3,0],
    [5,9,10,1,3,0,0,0,0],
    [5,9,3,10,7,1,0,0,0],
    [5,9,10,10,1,0,0,0,0],
    [5,9,10,10,6,1,0,0,0],
    [5,9,10,3,9,1,0,0,0],
    [5,9,10,10,1,3,7,0,0],
    [5,9,10,3,1,0,0,0,0],
    [5,9,10,3,1,4,0,0,0],
    [5,9,10,1,10,3,7,5,0],
    [5,9,3,10,10,1,0,0,0],
    [5,9,10,10,3,1,0,0,0],
    [5,9,10,4,3,10,9,1,0],
    [5,9,1,3,0,0,0,0,0],
    [5,9,10,3,5,1,0,0,0],
    [5,9,2,3,10,1,0,0,0],
    [5,9,10,3,1,0,0,0,0],
    [5,9,1,2,7,3,0,0,0],
    [5,9,10,1,10,3,0,0,0],
    [5,9,10,1,3,0,0,0,0],
    [5,9,10,3,4,1,0,0,0],
    [5,9,10,10,3,4,1,10,0],
    [5,9,3,10,1,0,0,0,0],
    [5,9,10,10,10,1,3,0,0],
    [5,9,10,7,1,10,0,0,0],
    [5,9,10,1,10,10,0,0,0],
    [5,9,10,1,3,0,0,0,0],
    [5,9,10,1,0,0,0,0,0],
    [5,9,10,10,3,4,1,0,0],
    [5,9,10,10,10,3,1,0,0],
    [5,9,10,1,0,0,0,0,0],
    [5,9,10,1,7,3,0,0,0],
    [5,9,3,10,7,1,0,0,0],
    [5,9,1,3,7,0,0,0,0],
    [5,9,4,3,1,6,0,0,0],
    [5,9,10,1,3,0,0,0,0],
    [5,9,10,1,3,10,7,0,0],
    [5,9,2,1,3,7,0,0,0],
    [5,9,10,7,10,1,3,0,0],
    [5,8,10,10,1,10,0,0,0],
    [5,9,10,10,7,3,1,2,0],
    [5,9,10,7,1,3,10,0,0],
    [5,9,10,1,10,3,7,10,0],
    [5,9,1,10,10,2,10,0,0],
    [5,9,10,10,1,0,0,0,0],
    [5,9,10,10,3,5,1,0,0],
    [5,9,10,10,1,10,10,10,0],
    [5,9,10,10,3,1,10,0,0],
    [5,9,10,1,10,6,0,0,0],
    [5,9,2,10,10,1,3,0,0],
    [5,9,10,10,1,0,0,0,0],
    [5,9,10,10,3,1,0,0,0],
    [5,9,10,10,3,2,1,0,0],
    [5,9,10,10,1,0,0,0,0],
    [1,9,10,10,1,0,0,0,0],
    [5,9,10,2,4,3,1,10,0],
    [5,9,10,1,3,7,0,0,0],
    [5,9,10,1,3,0,0,0,0],
    [5,9,10,10,2,1,3,4,0],
    [5,9,10,10,3,10,1,0,0],
    [5,9,10,10,10,3,1,0,0],
    [5,9,10,1,10,0,0,0,0],
    [5,9,10,10,1,10,3,0,0],
    [5,9,10,10,10,3,1,4,0],
    [5,9,10,3,1,0,0,0,0],
    [5,9,10,1,3,10,0,0,0],
    [5,9,10,3,10,10,1,0,0],
    [5,9,10,10,3,1,4,10,10],
    [5,9,10,10,4,10,10,1,0],
    [5,9,4,10,3,10,1,2,0],
    [5,9,10,10,3,1,0,0,0],
    [5,9,10,1,3,0,0,0,0],
    [5,9,7,1,5,10,3,0,0],
    [5,9,10,10,3,4,1,0,0],
    [5,9,4,10,3,1,10,0,0],
    [5,9,10,1,3,10,0,0,0],
    [5,9,10,10,3,1,0,0,0],
    [5,9,10,4,10,1,3,0,0],
    [5,9,10,10,3,1,0,0,0],
    [5,9,10,3,1,5,9,0,0],
    [1,9,10,1,3,9,0,0,0],
    [5,9,10,2,10,3,10,1,0],
    [5,9,10,3,4,1,10,0,0],
    [5,9,1,10,10,3,0,0,0],
    [5,9,3,10,1,10,0,0,0],
    [5,9,10,10,7,1,3,0,0]
    ];

    address  public compContract= address(0xABa31c041E916e4141036F080B554D40Cdb2BCD0);
    event Staking(address indexed from,uint32 power,uint256 amount);
    event Redeem(address indexed to,uint32 compId,uint32 power,uint256 amount);


    /**
   *
   * compPower
   *
   * Requirements
   * - `tokenId`  tokenId
   */
    function compPower(uint32 tokenId) public view returns(uint8){
        //fetch gene from contract
        IComp comp = IComp(compContract);
        string memory gene = comp.geneMap(tokenId);

        require(bytes(gene).length > 0,'token is not exist');

        uint8 power = 0;

        uint8[] memory geneIntArray = _geneToIntArray(gene);

        for(uint8 i= 1;i<geneIntArray.length; i++){
            if(geneIntArray[i]==99){ //stop flag
                //sex
                uint8 sexNum = geneIntArray[i-1];
                if(sexNum == 0){
                    power=power+5;
                }else if(sexNum==3){
                    power=power+1;
                }else{
                    power=power+3;
                }
                break;
            }
            //not sex gene and not match add 10 power
            else if((geneIntArray[i+1] != 99)  && (geneIntArray[i] != standTemplates[geneIntArray[0]][i-1] )){
                power=power+1;
            }
        }

        return power*10;

    }
    /**
   *
   * geneToIntArray
   *
   * Requirements
   * - `geneStr`  geneStr
   */
    function _geneToIntArray(string memory geneStr) private pure  returns(uint8[] memory){

        uint8[] memory geneIntArray = new uint8[](12);
        bytes memory genebytes = bytes (geneStr);
        uint8 tempValue = 0;
        uint length=0;
        for(uint256 i=0;i<genebytes.length;i++){
            uint8 c = uint8(genebytes[i]);
            //is number: 0-9
            if(c >= 48 && c <= 57){
                tempValue = tempValue*10 + (c - 48);
            }else{
                geneIntArray[length] = tempValue;
                tempValue = 0;
                length++;
            }
        }
        geneIntArray[length]=tempValue;

        geneIntArray[length+1] = 99; //stop flag
        return geneIntArray;

    }
    /**
   *
   * staking params
   *
   * Requirements
   * - `compIdList`  compIdList
   * - `poolTokenContract`
   */
    function currentStakingParams(uint32[] memory compIdList,address poolTokenContract) public view returns( uint32, uint256) {

        uint32 totalPower =0;
        for(uint8 i=0;i<compIdList.length;i++){
            totalPower += compPower(compIdList[i]);
        }
        return (totalPower,_currentStakingAmount(totalPower,poolTokenContract));
    }

    /**
   *
   * currentStakingAmount
   *
   * Requirements
   * - `power`  tokenId list
   * - `poolTokenContract`
   */
    function _currentStakingAmount(uint32 power,address poolTokenContract) private view returns( uint256) {
        PoolInfo memory pool = pools[poolTokenContract];
        require(pool.initOwner != address(0), "pool is not exist");

        uint availableBouns = poolAvailableBouns(poolTokenContract);

        return  pool.totalPower>0? (availableBouns * power / pool.totalPower) : (power*pool.initStakingRatio * 10**uint256(18));
    }

    function poolAvailableBouns(address poolTokenContract) public view returns(uint256){
        PoolInfo memory pool = pools[poolTokenContract];
        require(pool.initOwner != address(0), "pool is not exist");

        IComp comp = IComp(compContract);
        IERC20 poolBalance = IERC20(poolTokenContract);

        uint256 totalPower = pool.totalPower;
        uint256 maxTokenId = comp.tokenId();
        uint256 totalBouns = poolBalance.balanceOf(address(this));

        if(maxTokenId> pool.startRedeemTokenId && totalPower>0){ //start
            if(block.number<13600000){ //stop time
                totalBouns -= (10000-(maxTokenId-1)) * pool.onceCompReward * 10**uint256(18);
            }
        }else{
            totalBouns =  totalPower*pool.initStakingRatio * 10**uint256(18);
        }

        return totalBouns;
    }

    /**
  *
  * staking
  *
  * Requirements
  * - `compIdList`  tokenId list
  * - `poolTokenContract`
  */

    function staking(uint32[] memory compIdList , address poolTokenContract) public returns (bool){

        PoolInfo storage poolInfo = pools[poolTokenContract];
        require(poolInfo.initOwner != address(0), "pool is not exist");
        require(compIdList.length > 0 , "at least one comp");


        uint32 stakingPower = 0;
        for(uint8 i=0;i<compIdList.length;i++){

            IComp comp = IComp(compContract);
            address owner =  comp.ownerOf(compIdList[i]);

            require(owner==msg.sender, "must be owner of token");
            require(compStakingMap[poolTokenContract][compIdList[i]]==0,"already staking ");

            uint32 power = compPower(compIdList[i]);

            compStakingMap[poolTokenContract][compIdList[i]] = power;
            stakingPower += power;
        }
        uint256 stakingAmount = _currentStakingAmount(stakingPower,poolTokenContract);
        emit Staking(msg.sender,stakingPower,stakingAmount);

        IERC20 erc20 = IERC20(poolTokenContract);
        erc20.transferFrom(msg.sender,address(this), stakingAmount);
        poolInfo.totalPower +=  stakingPower;

        return true;
    }
    /**
  *
  * redeem staking
  *
  * Requirements
  * - `compId`  redeem compId
  * - `poolTokenContract`
  */
    function redeem(uint32 compId, address poolTokenContract)public returns (bool){

        PoolInfo storage poolInfo = pools[poolTokenContract];
        require(poolInfo.initOwner != address(0), "pool is not exist");

        IComp comp = IComp(compContract);
        address owner =  comp.ownerOf(compId);
        require(owner==msg.sender, "must be owner of token");
        require(compStakingMap[poolTokenContract][compId] !=0 , "not staking");

        uint32 power= compPower(compId);
        require(poolInfo.totalPower>=power, "power error");

        uint256  amount = _currentStakingAmount(power,poolTokenContract);

        poolInfo.totalPower -= power;

        IERC20 erc20 = IERC20(poolTokenContract);

        uint256 redeemAmount = poolInfo.totalPower > 0 ? (amount * 99 / 100): amount;
        erc20.transfer(msg.sender, redeemAmount);  //1% fee
        compStakingMap[poolTokenContract][compId] = 0;


        emit Redeem(msg.sender, compId,power,redeemAmount);

        return true;

    }

    /**
  *
  * add new pool
  *
  * Requirements
  * - `startRedeemTokenId`
  * - `poolTokenContract`
  * - `initStakingRatio`
  * - `onceCompReward`
  */
    function createPool(uint32 startRedeemTokenId,address poolTokenContract, uint32 initStakingRatio,uint32 onceCompReward) public returns (bool){

        PoolInfo storage poolInfo = pools[poolTokenContract];
        require(poolInfo.initOwner == address(0), "staking has started");

        IERC20 erc20 = IERC20(poolTokenContract);
        erc20.transferFrom(msg.sender,address(this), onceCompReward * 10000 * 10**uint256(18));

        poolInfo.startRedeemTokenId = startRedeemTokenId;
        poolInfo.poolTokenContract = poolTokenContract;
        poolInfo.initStakingRatio = initStakingRatio;
        poolInfo.onceCompReward = onceCompReward;
        poolInfo.initOwner = msg.sender;
        return true;
    }
}

