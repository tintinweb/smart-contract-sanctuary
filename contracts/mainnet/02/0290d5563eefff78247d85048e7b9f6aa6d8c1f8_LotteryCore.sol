pragma solidity ^0.4.18;

contract DogCoreInterface {
    address public ceoAddress;
    address public cfoAddress;
    function getDog(uint256 _id)
        external
        view
        returns (
        //冷却期索引号
        uint256 cooldownIndex,
        //本次冷却期结束所在区块
        uint256 nextActionAt,
        //配种的公狗ID
        uint256 siringWithId,
        //出生时间
        uint256 birthTime,
        //母亲ID
        uint256 matronId,
        //父亲ID
        uint256 sireId,
        //代数
        uint256 generation,
        //基因
        uint256 genes,
        //变异，0表示未变异，1-7表示变异
        uint8  variation,
        //0代祖先的ID
        uint256 gen0
    );
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function sendMoney(address _to, uint256 _money) external;
    function totalSupply() external view returns (uint);
}


/*
    LotteryBase 主要定义了开奖信息，奖金池转入函数以及判断是否开必中
*/
contract LotteryBase {
    
    // 当前开奖基因位数
    uint8 public currentGene;
    // 当前开奖所在区块
    uint256 public lastBlockNumber;
    // 随机数种子
    uint256 randomSeed = 1;
    // 奖金池地址
    address public bonusPool;
    // 中奖信息
    struct CLottery {
        // 该期中奖基因
        uint8[7]        luckyGenes;
        // 该期奖金池总额
        uint256         totalAmount;
        // 该期第7个基因开奖所在区块
        uint256         openBlock;
        // 是否发奖完毕
        bool            isReward;
        // 未开一等奖标记
        bool         noFirstReward;
    }
    // 历史开奖信息
    CLottery[] public CLotteries;
    // 发奖合约地址
    address public finalLottery;
    // 蓄奖池金额
    uint256 public SpoolAmount = 0;
    // 宠物信息接口
    DogCoreInterface public dogCore;
    // 随机开奖事件
    event OpenLottery(uint8 currentGene, uint8 luckyGenes, uint256 currentTerm, uint256 blockNumber, uint256 totalAmount);
    //必中开奖事件
    event OpenCarousel(uint256 luckyGenes, uint256 currentTerm, uint256 blockNumber, uint256 totalAmount);
    
    
    //
    modifier onlyCEO() {
        require(msg.sender == dogCore.ceoAddress());
        _;  
    }
    //
    modifier onlyCFO() {
        require(msg.sender == dogCore.cfoAddress());
        _;  
    }
    /*
        蓄奖池转入奖金池函数
    */
    function toLotteryPool(uint amount) public onlyCFO {
        require(SpoolAmount >= amount);
        SpoolAmount -= amount;
    }
    /*
    判断当期是否开必中
    */
    function _isCarousal(uint256 currentTerm) external view returns(bool) {
       return (currentTerm > 1 && CLotteries[currentTerm - 2].noFirstReward && CLotteries[currentTerm - 1].noFirstReward); 
    }
    
    /*
      返回当前期数
    */ 
    function getCurrentTerm() external view returns (uint256) {

        return (CLotteries.length - 1);
    }
}


/*
    LotteryGenes主要实现奖宠物原始基因转化为兑奖数组
*/
contract LotteryGenes is LotteryBase {
    /*
     将基因数字格式转换为抽奖数组格式
    */
    function convertGeneArray(uint256 gene) public pure returns(uint8[7]) {
        uint8[28] memory geneArray; 
        uint8[7] memory lotteryArray;
        uint index = 0;
        for (index = 0; index < 28; index++) {
            uint256 geneItem = gene % (2 ** (5 * (index + 1)));
            geneItem /= (2 ** (5 * index));
            geneArray[index] = uint8(geneItem);
        }
        for (index = 0; index < 7; index++) {
            uint size = 4 * index;
            lotteryArray[index] = geneArray[size];
            
        }
        return lotteryArray;
    }

    /**
       将显性基因串拼凑成原始基因数字
    */ 
    function convertGene(uint8[7] luckyGenes) public pure returns(uint256) {
        uint8[28] memory geneArray;
        for (uint8 i = 0; i < 28; i++) {
            if (i%4 == 0) {
                geneArray[i] = luckyGenes[i/4];
            } else {
                geneArray[i] = 6;
            }
        }
        uint256 gene = uint256(geneArray[0]);
        
        for (uint8 index = 1; index < 28; index++) {
            uint256 geneItem = uint256(geneArray[index]);
            gene += geneItem << (index * 5);
        }
        return gene;
    }
}


/*
    SetLottery主要实现了随机开奖和必中开奖
*/
contract SetLottery is LotteryGenes {

    function random(uint8 seed) internal returns(uint8) {
        randomSeed = block.timestamp;
        return uint8(uint256(keccak256(randomSeed, block.difficulty))%seed)+1;
    }

    /*
     随机开奖函数，每一期开7次。
     currentGene表示当期开奖的第N个基因
     若当前currentGene指标为0，则表示在开奖期未开任何数字，或者开奖期已经开完了所有数字
     当前开奖期最后一个基因开完后，记录当前所在区块号和当前奖金池金额
     返回值分别为当前开奖基因(0代表不存在)、查询开奖基因(0代表不存在)、
     开奖状态(0表示开奖成功，1表示当期开奖结束且在等待发奖，2表示当前基因开奖区块与上个基因开奖区块相同,3表示奖金池金额不足)
     */
    function openLottery(uint8 _viewId) public returns(uint8,uint8) {
        uint8 viewId = _viewId;
        require(viewId < 7);
        // 获取当前中奖信息
        uint256 currentTerm = CLotteries.length - 1;
        CLottery storage clottery = CLotteries[currentTerm];

        // 如果7个基因都完成开奖并且当期没有发奖，则说明当期所有基因已经开奖完毕在等待发奖，退出
        if (currentGene == 0 && clottery.openBlock > 0 && clottery.isReward == false) {
            // 触发事件，返回查询的基因
            OpenLottery(viewId, clottery.luckyGenes[viewId], currentTerm, 0, 0);
            //分别返回查询基因，状态1 (表示当期所有基因开奖完毕在等待发奖)
            return (clottery.luckyGenes[viewId],1);
        }
        // 如果上个基因开奖和本次开奖在同一个区块，退出
        if (lastBlockNumber == block.number) {
            // 触发事件，返回查询的基因
            OpenLottery(viewId, clottery.luckyGenes[viewId], currentTerm, 0, 0);
            //分别返回查询基因，状态2 (当前基因开奖区块与上个基因开奖区块相同)
            return (clottery.luckyGenes[viewId],2);
        }
        // 如果当前开奖基因位为0且当期已经发奖，则进入下一期开奖
        if (currentGene == 0 && clottery.isReward == true) {
            // 初始化当前lottery信息
            CLottery memory _clottery;
            _clottery.luckyGenes = [0,0,0,0,0,0,0];
            _clottery.totalAmount = uint256(0);
            _clottery.isReward = false;
            _clottery.openBlock = uint256(0);
            currentTerm = CLotteries.push(_clottery) - 1;
        }

        // 如果前两期都没有一等奖产生，则该期产生必中奖，退出随机开奖函数
        if (this._isCarousal(currentTerm)) {
            revert();
        }

        //开奖结果
        uint8 luckyNum = 0;
        
        if (currentGene == 6) {
            // 如果奖金池金额为零，则退出
            if (bonusPool.balance <= SpoolAmount) {
                // 触发事件，返回查询的基因
                OpenLottery(viewId, clottery.luckyGenes[viewId], currentTerm, 0, 0);
                //分别返回查询基因，状态3 (奖金池金额不足)
                return (clottery.luckyGenes[viewId],3);
            }
            //将随机数赋值给当前基因
            luckyNum = random(8);
            CLotteries[currentTerm].luckyGenes[currentGene] = luckyNum;
            //触发开奖事件
            OpenLottery(currentGene, luckyNum, currentTerm, block.number, bonusPool.balance);
            //如果当前为最后一个开奖基因，则下一个开奖基因位为0，同时记录下当前区块号并写入开奖信息，同时将奖金池金额写入开奖信息, 同时启动主合约
            currentGene = 0;
            CLotteries[currentTerm].openBlock = block.number;
            CLotteries[currentTerm].totalAmount = bonusPool.balance;
            //记录当前开奖所在区块
            lastBlockNumber = block.number;
        } else { 
            //将随机数赋值给当前基因
        
            luckyNum = random(12);
            CLotteries[currentTerm].luckyGenes[currentGene] = luckyNum;

            //触发开奖事件
            OpenLottery(currentGene, luckyNum, currentTerm, 0, 0);
            //其它情况下，下一个开奖基因位加1
            currentGene ++;
            //记录当前开奖所在区块
            lastBlockNumber = block.number;
        }
        //分别返回开奖基因，查询基因和开奖成功状态
        return (luckyNum,0);
    } 

    function random2() internal view returns (uint256) {
        return uint256(uint256(keccak256(block.timestamp, block.difficulty))%uint256(dogCore.totalSupply()) + 1);
    }

    /*
     必中开奖函数,每期开一次
    */
    function openCarousel() public {
        //获取当前开奖信息
        uint256 currentTerm = CLotteries.length - 1;
        CLottery storage clottery = CLotteries[currentTerm];

        // 如果当前开奖基因指针为0且开奖基因存在，且未发奖，则说明当前基因开奖完毕，在等待发奖
        if (currentGene == 0 && clottery.openBlock > 0 && clottery.isReward == false) {

            //触发开奖事件,返回当期现有开奖数据
            OpenCarousel(convertGene(clottery.luckyGenes), currentTerm, clottery.openBlock, clottery.totalAmount);
        }

        // 如果开奖基因指针为0且开奖基因存在，并且发奖完毕，则进入下一开奖周期
        if (currentGene == 0 && clottery.openBlock > 0 && clottery.isReward == true) {
            CLottery memory _clottery;
            _clottery.luckyGenes = [0,0,0,0,0,0,0];
            _clottery.totalAmount = uint256(0);
            _clottery.isReward = false;
            _clottery.openBlock = uint256(0);
            currentTerm = CLotteries.push(_clottery) - 1;
        }

        //期数大于3 且前三期未产生特等奖
        require (this._isCarousal(currentTerm));
        // 随机获取必中基因
        uint256 genes = _getValidRandomGenes();
        require (genes > 0);
        uint8[7] memory luckyGenes = convertGeneArray(genes);
        //触发开奖事件
        OpenCarousel(genes, currentTerm, block.number, bonusPool.balance);

        //写入记录
        CLotteries[currentTerm].luckyGenes = luckyGenes;
        CLotteries[currentTerm].openBlock = block.number;
        CLotteries[currentTerm].totalAmount = bonusPool.balance;
        
    }
    
    /*
      随机获取合法的必中基因
    */
    function _getValidRandomGenes() internal view returns (uint256) {
        uint256 luckyDog = random2();
        uint256 genes = _validGenes(luckyDog);
        uint256 totalSupply = dogCore.totalSupply();
        if (genes > 0) {
            return genes;
        }  
        // 如果dog不能兑奖，则渐进振荡判断其它dog是否满足条件
        uint256 min = (luckyDog < totalSupply-luckyDog) ? (luckyDog - 1) : totalSupply-luckyDog;
        for (uint256 i = 1; i < min + 1; i++) {
            genes = _validGenes(luckyDog - i);
            if (genes > 0) {
                break;
            }
            genes = _validGenes(luckyDog + i);
            if (genes > 0) {
                    break;
                }
            }
            // min次震荡仍然未找到可兑奖基因
        if (genes == 0) {
            //luckyDog右侧更长
            if (min == luckyDog - 1) {
                for (i = min + luckyDog; i < totalSupply + 1; i++) {
                        genes = _validGenes(i);
                        if (genes > 0) {
                            break;
                        }
                    }   
                }
            //luckyDog左侧更长
            if (min == totalSupply - luckyDog) {
                for (i = min; i < luckyDog; i++) {
                        genes = _validGenes(luckyDog - i - 1);
                        if (genes > 0) {
                            break;
                        }
                    }   
                }
            }
        return genes;
    }


    /*
      判断狗是否能兑奖，能则直接返回狗的基因，不能则返回0
    */
    function _validGenes(uint256 dogId) internal view returns (uint256) {

        var(, , , , , ,generation, genes, variation,) = dogCore.getDog(dogId);
        if (generation == 0 || dogCore.ownerOf(dogId) == finalLottery || variation > 0) {
            return 0;
        } else {
            return genes;
        }
    }

    
}

/*
  LotteryCore是开奖函数的入口合约
  开奖包括必中开奖和随机开奖
  同时LotteryCore提供对外查询接口
*/

contract LotteryCore is SetLottery {
    
    // 构造函数，传入奖金池地址,初始化中奖信息
    function LotteryCore(address _ktAddress) public {

        bonusPool = _ktAddress;
        dogCore = DogCoreInterface(_ktAddress);

        //初始化中奖信息
        CLottery memory _clottery;
        _clottery.luckyGenes = [0,0,0,0,0,0,0];
        _clottery.totalAmount = uint256(0);
        _clottery.isReward = false;
        _clottery.openBlock = uint256(0);
        CLotteries.push(_clottery);
    }
    /*
    设置FinalLottery地址
    */
    function setFinalLotteryAddress(address _flAddress) public onlyCEO {
        finalLottery = _flAddress;
    }
    /*
    获取当前中奖记录
    */
    function getCLottery() 
        public 
        view 
        returns (
            uint8[7]        luckyGenes,
            uint256         totalAmount,
            uint256         openBlock,
            bool            isReward,
            uint256         term
        ) {
            term = CLotteries.length - uint256(1);
            luckyGenes = CLotteries[term].luckyGenes;
            totalAmount = CLotteries[term].totalAmount;
            openBlock = CLotteries[term].openBlock;
            isReward = CLotteries[term].isReward;
    }

    /*
    更改发奖状态
    */
    function rewardLottery(bool isMore) external {
        // require contract address is final lottery
        require(msg.sender == finalLottery);

        uint256 term = CLotteries.length - 1;
        CLotteries[term].isReward = true;
        CLotteries[term].noFirstReward = isMore;
    }

    /*
    转入蓄奖池
    */
    function toSPool(uint amount) external {
        // require contract address is final lottery
        require(msg.sender == finalLottery);

        SpoolAmount += amount;
    }
}


/*
    FinalLottery 包含兑奖函数和发奖函数
    中奖信息flotteries存入开奖期数到[各等奖获奖者，各等奖中奖金额]的映射
*/
contract FinalLottery {
    bool public isLottery = true;
    LotteryCore lotteryCore;
    DogCoreInterface dogCore;
    uint8[7] public luckyGenes;
    uint256         totalAmount;
    uint256         openBlock;
    bool            isReward;
    uint256         currentTerm;
    uint256  public duration;
    uint8   public  lotteryRatio;
    uint8[7] public lotteryParam;
    uint8   public  carousalRatio;
    uint8[7] public carousalParam; 
    // 中奖信息
    struct FLottery {
        //  该期各等奖获奖者
        //  一等奖
        address[]        owners0;
        uint256[]        dogs0;
        //  二等奖
        address[]        owners1;
        uint256[]        dogs1;
        //  三等奖
        address[]        owners2;
        uint256[]        dogs2;
        //  四等奖
        address[]        owners3;
        uint256[]        dogs3;
        //  五等奖
        address[]        owners4;
        uint256[]        dogs4;
        //  六等奖
        address[]        owners5;
        uint256[]        dogs5;
        //  七等奖
        address[]        owners6;
        uint256[]        dogs6;
        // 中奖金额
        uint256[]       reward;
    }
    // 兑奖发奖信息
    mapping(uint256 => FLottery) flotteries;
    // 构造函数
    function FinalLottery(address _lcAddress) public {
        lotteryCore = LotteryCore(_lcAddress);
        dogCore = DogCoreInterface(lotteryCore.bonusPool());
        duration = 11520;
        lotteryRatio = 23;
        lotteryParam = [46,16,10,9,8,6,5];
        carousalRatio = 12;
        carousalParam = [35,18,14,12,8,7,6];
        
    }
    
    // 发奖事件
    event DistributeLottery(uint256[] rewardArray, uint256 currentTerm);
    // 兑奖事件
    event RegisterLottery(uint256 dogId, address owner, uint8 lotteryClass, string result);
    // 设置兑奖周期
    function setLotteryDuration(uint256 durationBlocks) public {
        require(msg.sender == dogCore.ceoAddress());
        require(durationBlocks > 140);
        require(durationBlocks < block.number);
        duration = durationBlocks;
    }
    /*
     登记兑奖函数,发生在当期开奖结束之后7天内（即40，320个区块内）
    */
    function registerLottery(uint256 dogId) public returns (uint8) {
        uint256 _dogId = dogId;
        (luckyGenes, totalAmount, openBlock, isReward, currentTerm) = lotteryCore.getCLottery();
        // 获取当前开奖信息
        address owner = dogCore.ownerOf(_dogId);
        // 回收的不能兑奖
        require (owner != address(this));
        // 调用者必须是主合约
        require(address(dogCore) == msg.sender);
        // 所有基因位开奖完毕（指针为0同时奖金池大于0）且未发奖且未兑奖结束
        require(totalAmount > 0 && isReward == false && openBlock > (block.number-duration));
        // 获取该宠物的基因，代数，出生时间
        var(, , , birthTime, , ,generation,genes, variation,) = dogCore.getDog(_dogId);
        // 出生日期小于开奖时间
        require(birthTime < openBlock);
        // 0代狗不能兑奖
        require(generation > 0);
        // 变异的不能兑奖
        require(variation == 0);
        // 判断该用户获几等奖，100表示未中奖
        uint8 _lotteryClass = getLotteryClass(luckyGenes, genes);
        // 若未获奖则退出
        require(_lotteryClass < 7);
        // 避免重复兑奖
        address[] memory owners;
        uint256[] memory dogs;
         (dogs, owners) = _getLuckyList(currentTerm, _lotteryClass);
            
        for (uint i = 0; i < dogs.length; i++) {
            if (_dogId == dogs[i]) {
            //    revert();
                RegisterLottery(_dogId, owner, _lotteryClass,"dog already registered");
                 return 5;
            }
        }
        // 将登记中奖者的账户存入奖金信息表
        _pushLuckyInfo(currentTerm, _lotteryClass, owner, _dogId);
        // 触发兑奖成功事件
        RegisterLottery(_dogId, owner, _lotteryClass,"successful");
        return 0;
    }
    /*
    发奖函数，发生在当期开奖结束之后
    */
    
    function distributeLottery() public returns (uint8) {
        (luckyGenes, totalAmount, openBlock, isReward, currentTerm) = lotteryCore.getCLottery();
        
        // 必须在当期开奖结束一周之后发奖
        require(openBlock > 0 && openBlock < (block.number-duration));

        //奖金池可用金额必须大于或等于0
        require(totalAmount >= lotteryCore.SpoolAmount());

        // 如果已经发奖
        if (isReward == true) {
            DistributeLottery(flotteries[currentTerm].reward, currentTerm);
            return 1;
        }
        uint256 legalAmount = totalAmount - lotteryCore.SpoolAmount();
        uint256 totalDistribute = 0;
        uint8[7] memory lR;
        uint8 ratio;

        // 必中和随机两种不同的奖金分配比率
        if (lotteryCore._isCarousal(currentTerm) ) {
            lR = carousalParam;
            ratio = carousalRatio;
        } else {
            lR = lotteryParam;
            ratio = lotteryRatio;
        }
        // 计算各奖项金额并分发给中奖者
        for (uint8 i = 0; i < 7; i++) {
            address[] memory owners;
            uint256[] memory dogs;
            (dogs, owners) = _getLuckyList(currentTerm, i);
            if (owners.length > 0) {
                    uint256 reward = (legalAmount * ratio * lR[i])/(10000 * owners.length);
                    totalDistribute += reward * owners.length;
                    // 转给CFO的手续费（10%）
                    dogCore.sendMoney(dogCore.cfoAddress(),reward * owners.length/10);
                    
                    for (uint j = 0; j < owners.length; j++) {
                        address gen0Add;
                        if (i == 0) {
                            // 转账
                            dogCore.sendMoney(owners[j],reward*95*9/1000);
                            // gen0 奖励
                            gen0Add = _getGen0Address(dogs[j]);
                            assert(gen0Add != address(0));
                            dogCore.sendMoney(gen0Add,reward*5/100);
                        } else if (i == 1) {
                            // 转账
                            dogCore.sendMoney(owners[j],reward*97*9/1000);
                            // gen0 奖励
                            gen0Add = _getGen0Address(dogs[j]);
                            assert(gen0Add != address(0));
                            dogCore.sendMoney(gen0Add,reward*3/100);
                        } else if (i == 2) {
                            // 转账
                            dogCore.sendMoney(owners[j],reward*98*9/1000);
                            // gen0 奖励
                            gen0Add = _getGen0Address(dogs[j]);
                            assert(gen0Add != address(0));
                            dogCore.sendMoney(gen0Add,reward*2/100);
                        } else {
                            // 转账
                            dogCore.sendMoney(owners[j],reward*9/10);
                        }
                    }
                  // 记录各等奖发奖金额
                    flotteries[currentTerm].reward.push(reward);  
                } else {
                    flotteries[currentTerm].reward.push(0); 
                } 
        }
        //没有人登记一等奖中奖，将奖金池5%转入蓄奖池,并且更新无一等奖计数
        if (flotteries[currentTerm].owners0.length == 0) {
            lotteryCore.toSPool((lotteryCore.bonusPool().balance - lotteryCore.SpoolAmount())/20);
            lotteryCore.rewardLottery(true);
        } else {
            //发奖完成之后，更新当前奖项状态、将当前奖项加入历史记录
            lotteryCore.rewardLottery(false);
        }
        
        DistributeLottery(flotteries[currentTerm].reward, currentTerm);
        return 0;
    }

     /*
    获取狗的gen0祖先的主人账户
    */
    function _getGen0Address(uint256 dogId) internal view returns(address) {
        var(, , , , , , , , , gen0) = dogCore.getDog(dogId);
        return dogCore.ownerOf(gen0);
    }

    /*
      通过奖项等级获取中奖者列表和中奖狗列表
    */
    function _getLuckyList(uint256 currentTerm1, uint8 lotclass) public view returns (uint256[] kts, address[] ons) {
        if (lotclass==0) {
            ons = flotteries[currentTerm1].owners0;
            kts = flotteries[currentTerm1].dogs0;
        } else if (lotclass==1) {
            ons = flotteries[currentTerm1].owners1;
            kts = flotteries[currentTerm1].dogs1;
        } else if (lotclass==2) {
            ons = flotteries[currentTerm1].owners2;
            kts = flotteries[currentTerm1].dogs2;
        } else if (lotclass==3) {
            ons = flotteries[currentTerm1].owners3;
            kts = flotteries[currentTerm1].dogs3;
        } else if (lotclass==4) {
            ons = flotteries[currentTerm1].owners4;
            kts = flotteries[currentTerm1].dogs4;
        } else if (lotclass==5) {
            ons = flotteries[currentTerm1].owners5;
            kts = flotteries[currentTerm1].dogs5;
        } else if (lotclass==6) {
            ons = flotteries[currentTerm1].owners6;
            kts = flotteries[currentTerm1].dogs6;
        }
    }

    /*
      将owner和dogId推入中奖信息存储
    */
    function _pushLuckyInfo(uint256 currentTerm1, uint8 _lotteryClass, address owner, uint256 _dogId) internal {
        if (_lotteryClass == 0) {
            flotteries[currentTerm1].owners0.push(owner);
            flotteries[currentTerm1].dogs0.push(_dogId);
        } else if (_lotteryClass == 1) {
            flotteries[currentTerm1].owners1.push(owner);
            flotteries[currentTerm1].dogs1.push(_dogId);
        } else if (_lotteryClass == 2) {
            flotteries[currentTerm1].owners2.push(owner);
            flotteries[currentTerm1].dogs2.push(_dogId);
        } else if (_lotteryClass == 3) {
            flotteries[currentTerm1].owners3.push(owner);
            flotteries[currentTerm1].dogs3.push(_dogId);
        } else if (_lotteryClass == 4) {
            flotteries[currentTerm1].owners4.push(owner);
            flotteries[currentTerm1].dogs4.push(_dogId);
        } else if (_lotteryClass == 5) {
            flotteries[currentTerm1].owners5.push(owner);
            flotteries[currentTerm1].dogs5.push(_dogId);
        } else if (_lotteryClass == 6) {
            flotteries[currentTerm1].owners6.push(owner);
            flotteries[currentTerm1].dogs6.push(_dogId);
        }
    }

    /*
      检测该基因获奖等级
    */
    function getLotteryClass(uint8[7] luckyGenesArray, uint256 genes) internal view returns(uint8) {
        // 不存在开奖信息,则直接返回未中奖
        if (currentTerm < 0) {
            return 100;
        }
        
        uint8[7] memory dogArray = lotteryCore.convertGeneArray(genes);
        uint8 cnt = 0;
        uint8 lnt = 0;
        for (uint i = 0; i < 6; i++) {

            if (luckyGenesArray[i] > 0 && luckyGenesArray[i] == dogArray[i]) {
                cnt++;
            }
        }
        if (luckyGenesArray[6] > 0 && luckyGenesArray[6] == dogArray[6]) {
            lnt = 1;
        }
        uint8 lotclass = 100;
        if (cnt==6 && lnt==1) {
            lotclass = 0;
        } else if (cnt==6 && lnt==0) {
            lotclass = 1;
        } else if (cnt==5 && lnt==1) {
            lotclass = 2;
        } else if (cnt==5 && lnt==0) {
            lotclass = 3;
        } else if (cnt==4 && lnt==1) {
            lotclass = 4;
        } else if (cnt==3 && lnt==1) {
            lotclass = 5;
        } else if (cnt==3 && lnt==0) {
            lotclass = 6;
        } else {
            lotclass = 100;
        }
        return lotclass;
    }
    /*
       检测该基因获奖等级接口
    */
    function checkLottery(uint256 genes) public view returns(uint8) {
        var(luckyGenesArray, , , isReward1, ) = lotteryCore.getCLottery();
        if (isReward1) {
            return 100;
        }
        return getLotteryClass(luckyGenesArray, genes);
    }
    /*
       获取当前Lottery信息
    */
    function getCLottery() 
        public 
        view 
        returns (
            uint8[7]        luckyGenes1,
            uint256         totalAmount1,
            uint256         openBlock1,
            bool            isReward1,
            uint256         term1,
            uint8           currentGenes1,
            uint256         tSupply,
            uint256         sPoolAmount1,
            uint256[]       reward1
        ) {
            (luckyGenes1, totalAmount1, openBlock1, isReward1, term1) = lotteryCore.getCLottery();
            currentGenes1 = lotteryCore.currentGene();
            tSupply = dogCore.totalSupply();
            sPoolAmount1 = lotteryCore.SpoolAmount();
            reward1 = flotteries[term1].reward;
    }
    
}