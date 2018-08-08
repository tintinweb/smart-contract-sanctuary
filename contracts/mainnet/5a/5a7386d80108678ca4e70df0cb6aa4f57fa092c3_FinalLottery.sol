pragma solidity ^0.4.18;

contract DogCoreInterface {

    address public ceoAddress;
    address public cfoAddress;

    function getDog(uint256 _id)
        external
        view
        returns (
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes,
        uint8  variation,
        uint256 gen0
    );
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function sendMoney(address _to, uint256 _money) external;
    function totalSupply() external view returns (uint);
    function getOwner(uint256 _tokenId) public view returns(address);
    function getAvailableBlance() external view returns(uint256);
}


contract LotteryBase {
    
    uint8 public currentGene;
    
    uint256 public lastBlockNumber;
    
    uint256 randomSeed = 1;

    struct CLottery {
        
        uint8[7]        luckyGenes;
        
        uint256         totalAmount;
        
        uint256         openBlock;
        
        bool            isReward;
        
        bool         noFirstReward;
    }
    
    CLottery[] public CLotteries;
    
    address public finalLottery;
    
    uint256 public SpoolAmount = 0;
    
    DogCoreInterface public dogCore;
    
    event OpenLottery(uint8 currentGene, uint8 luckyGenes, uint256 currentTerm, uint256 blockNumber, uint256 totalAmount);
    
    event OpenCarousel(uint256 luckyGenes, uint256 currentTerm, uint256 blockNumber, uint256 totalAmount);
    
    
    modifier onlyCEO() {
        require(msg.sender == dogCore.ceoAddress());
        _;  
    }
    
    modifier onlyCFO() {
        require(msg.sender == dogCore.cfoAddress());
        _;  
    }
    
    function toLotteryPool(uint amount) public onlyCFO {
        require(SpoolAmount >= amount);
        SpoolAmount -= amount;
    }
    
    function _isCarousal(uint256 currentTerm) external view returns(bool) {
       return (currentTerm > 1 && CLotteries[currentTerm - 2].noFirstReward && CLotteries[currentTerm - 1].noFirstReward); 
    }
    
    function getCurrentTerm() external view returns (uint256) {

        return (CLotteries.length - 1);
    }
}


contract LotteryGenes is LotteryBase {
    
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


contract SetLottery is LotteryGenes {

    function random(uint8 seed) internal returns(uint8) {
        randomSeed = block.timestamp;
        return uint8(uint256(keccak256(randomSeed, block.difficulty))%seed)+1;
    }

    function openLottery(uint8 _viewId) public returns(uint8,uint8) {
        uint8 viewId = _viewId;
        require(viewId < 7);
        uint256 currentTerm = CLotteries.length - 1;
        CLottery storage clottery = CLotteries[currentTerm];

        if (currentGene == 0 && clottery.openBlock > 0 && clottery.isReward == false) {
            OpenLottery(viewId, clottery.luckyGenes[viewId], currentTerm, clottery.openBlock, clottery.totalAmount);
            return (clottery.luckyGenes[viewId],1);
        }
        if (lastBlockNumber == block.number) {
            OpenLottery(viewId, clottery.luckyGenes[viewId], currentTerm, clottery.openBlock, clottery.totalAmount);
            return (clottery.luckyGenes[viewId],2);
        }
        if (currentGene == 0 && clottery.isReward == true) {
            CLottery memory _clottery;
            _clottery.luckyGenes = [0,0,0,0,0,0,0];
            _clottery.totalAmount = uint256(0);
            _clottery.isReward = false;
            _clottery.openBlock = uint256(0);
            currentTerm = CLotteries.push(_clottery) - 1;
        }

        if (this._isCarousal(currentTerm)) {
            revert();
        }

        uint8 luckyNum = 0;
        
        uint256 bonusBalance = dogCore.getAvailableBlance();
        if (currentGene == 6) {
            if (bonusBalance <= SpoolAmount) {
                OpenLottery(viewId, clottery.luckyGenes[viewId], currentTerm, 0, 0);
                return (clottery.luckyGenes[viewId],3);
            }
            luckyNum = random(8);
            CLotteries[currentTerm].luckyGenes[currentGene] = luckyNum;
            OpenLottery(currentGene, luckyNum, currentTerm, block.number, bonusBalance);
            currentGene = 0;
            CLotteries[currentTerm].openBlock = block.number;
            CLotteries[currentTerm].totalAmount = bonusBalance;
            lastBlockNumber = block.number;
        } else {         
            luckyNum = random(12);
            CLotteries[currentTerm].luckyGenes[currentGene] = luckyNum;

            OpenLottery(currentGene, luckyNum, currentTerm, 0, 0);
            currentGene ++;
            lastBlockNumber = block.number;
        }
        return (luckyNum,0);
    } 

    function random2() internal view returns (uint256) {
        return uint256(uint256(keccak256(block.timestamp, block.difficulty))%uint256(dogCore.totalSupply()) + 1);
    }

    function openCarousel() public {
        uint256 currentTerm = CLotteries.length - 1;
        CLottery storage clottery = CLotteries[currentTerm];

        if (currentGene == 0 && clottery.openBlock > 0 && clottery.isReward == false) {

            OpenCarousel(convertGene(clottery.luckyGenes), currentTerm, clottery.openBlock, clottery.totalAmount);
        }

        if (currentGene == 0 && clottery.openBlock > 0 && clottery.isReward == true) {
            CLottery memory _clottery;
            _clottery.luckyGenes = [0,0,0,0,0,0,0];
            _clottery.totalAmount = uint256(0);
            _clottery.isReward = false;
            _clottery.openBlock = uint256(0);
            currentTerm = CLotteries.push(_clottery) - 1;
        }

        uint256 bonusBlance = dogCore.getAvailableBlance();

        require (this._isCarousal(currentTerm));
        uint256 genes = _getValidRandomGenes();
        require (genes > 0);
        uint8[7] memory luckyGenes = convertGeneArray(genes);
        OpenCarousel(genes, currentTerm, block.number, bonusBlance);

        CLotteries[currentTerm].luckyGenes = luckyGenes;
        CLotteries[currentTerm].openBlock = block.number;
        CLotteries[currentTerm].totalAmount = bonusBlance;        
    }
    
    function _getValidRandomGenes() internal view returns (uint256) {
        uint256 luckyDog = random2();
        uint256 genes = _validGenes(luckyDog);
        uint256 totalSupply = dogCore.totalSupply();
        if (genes > 0) {
            return genes;
        }  
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
        if (genes == 0) {
            if (min == luckyDog - 1) {
                for (i = min + luckyDog; i < totalSupply + 1; i++) {
                        genes = _validGenes(i);
                        if (genes > 0) {
                            break;
                        }
                    }   
                }
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


    function _validGenes(uint256 dogId) internal view returns (uint256) {

        var(, , , , , ,generation, genes, variation,) = dogCore.getDog(dogId);
        if (generation == 0 || dogCore.ownerOf(dogId) == finalLottery || variation > 0) {
            return 0;
        } else {
            return genes;
        }
    }

    
}


contract LotteryCore is SetLottery {
    
    function LotteryCore(address _ktAddress) public {

        dogCore = DogCoreInterface(_ktAddress);

        CLottery memory _clottery;
        _clottery.luckyGenes = [0,0,0,0,0,0,0];
        _clottery.totalAmount = uint256(0);
        _clottery.isReward = false;
        _clottery.openBlock = uint256(0);
        CLotteries.push(_clottery);
    }

    function setFinalLotteryAddress(address _flAddress) public onlyCEO {
        finalLottery = _flAddress;
    }
    
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

    function rewardLottery(bool isMore) external {
        require(msg.sender == finalLottery);

        uint256 term = CLotteries.length - 1;
        CLotteries[term].isReward = true;
        CLotteries[term].noFirstReward = isMore;
    }

    function toSPool(uint amount) external {
        
        require(msg.sender == finalLottery);

        SpoolAmount += amount;
    }
}


contract FinalLottery {
    bool public isLottery = true;
    LotteryCore public lotteryCore;
    DogCoreInterface public dogCore;
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
    
    struct FLottery {
        address[]        owners0;
        uint256[]        dogs0;
        address[]        owners1;
        uint256[]        dogs1;
        address[]        owners2;
        uint256[]        dogs2;
        address[]        owners3;
        uint256[]        dogs3;
        address[]        owners4;
        uint256[]        dogs4;
        address[]        owners5;
        uint256[]        dogs5;
        address[]        owners6;
        uint256[]        dogs6;
        uint256[]       reward;
    }
    mapping(uint256 => FLottery) flotteries;

    function FinalLottery(address _lcAddress) public {
        lotteryCore = LotteryCore(_lcAddress);
        dogCore = DogCoreInterface(lotteryCore.dogCore());
        duration = 11520;
        lotteryRatio = 23;
        lotteryParam = [46,16,10,9,8,6,5];
        carousalRatio = 12;
        carousalParam = [35,18,14,12,8,7,6];        
    }
    
    event DistributeLottery(uint256[] rewardArray, uint256 currentTerm);
    
    event RegisterLottery(uint256 dogId, address owner, uint8 lotteryClass, string result);
    
    function setLotteryDuration(uint256 durationBlocks) public {
        require(msg.sender == dogCore.ceoAddress());
        require(durationBlocks > 140);
        require(durationBlocks < block.number);
        duration = durationBlocks;
    }
    
    function registerLottery(uint256 dogId) public returns (uint8) {
        uint256 _dogId = dogId;
        (luckyGenes, totalAmount, openBlock, isReward, currentTerm) = lotteryCore.getCLottery();
        address owner = dogCore.ownerOf(_dogId);
        require (owner != address(this));
        require(address(dogCore) == msg.sender);
        require(totalAmount > 0 && isReward == false && openBlock > (block.number-duration));
        var(, , , birthTime, , ,generation,genes, variation,) = dogCore.getDog(_dogId);
        require(birthTime < openBlock);
        require(generation > 0);
        require(variation == 0);
        uint8 _lotteryClass = getLotteryClass(luckyGenes, genes);
        require(_lotteryClass < 7);
        address[] memory owners;
        uint256[] memory dogs;
         (dogs, owners) = _getLuckyList(currentTerm, _lotteryClass);
            
        for (uint i = 0; i < dogs.length; i++) {
            if (_dogId == dogs[i]) {
                RegisterLottery(_dogId, owner, _lotteryClass,"dog already registered");
                 return 5;
            }
        }
        _pushLuckyInfo(currentTerm, _lotteryClass, owner, _dogId);
        
        RegisterLottery(_dogId, owner, _lotteryClass,"successful");
        return 0;
    }
    
    function distributeLottery() public returns (uint8) {
        (luckyGenes, totalAmount, openBlock, isReward, currentTerm) = lotteryCore.getCLottery();
        
        require(openBlock > 0 && openBlock < (block.number-duration));

        require(totalAmount >= lotteryCore.SpoolAmount());

        if (isReward == true) {
            DistributeLottery(flotteries[currentTerm].reward, currentTerm);
            return 1;
        }
        uint256 legalAmount = totalAmount - lotteryCore.SpoolAmount();
        uint256 totalDistribute = 0;
        uint8[7] memory lR;
        uint8 ratio;

        if (lotteryCore._isCarousal(currentTerm) ) {
            lR = carousalParam;
            ratio = carousalRatio;
        } else {
            lR = lotteryParam;
            ratio = lotteryRatio;
        }
        for (uint8 i = 0; i < 7; i++) {
            address[] memory owners;
            uint256[] memory dogs;
            (dogs, owners) = _getLuckyList(currentTerm, i);
            if (owners.length > 0) {
                    uint256 reward = (legalAmount * ratio * lR[i])/(10000 * owners.length);
                    totalDistribute += reward * owners.length;
                    dogCore.sendMoney(dogCore.cfoAddress(),reward * owners.length/10);
                    
                    for (uint j = 0; j < owners.length; j++) {
                        address gen0Add;
                        if (i == 0) {
                            dogCore.sendMoney(owners[j],reward*95*9/1000);
                            gen0Add = _getGen0Address(dogs[j]);
                            if(gen0Add != address(0)){
                                dogCore.sendMoney(gen0Add,reward*5/100);
                            }
                        } else if (i == 1) {
                            dogCore.sendMoney(owners[j],reward*97*9/1000);
                            gen0Add = _getGen0Address(dogs[j]);
                            if(gen0Add != address(0)){
                                dogCore.sendMoney(gen0Add,reward*3/100);
                            }
                        } else if (i == 2) {
                            dogCore.sendMoney(owners[j],reward*98*9/1000);
                            gen0Add = _getGen0Address(dogs[j]);
                            if(gen0Add != address(0)){
                                dogCore.sendMoney(gen0Add,reward*2/100);
                            }
                        } else {
                            dogCore.sendMoney(owners[j],reward*9/10);
                        }
                    }
                    flotteries[currentTerm].reward.push(reward); 
                } else {
                    flotteries[currentTerm].reward.push(0);
                } 
        }
        if (flotteries[currentTerm].owners0.length == 0) {
            lotteryCore.toSPool((dogCore.getAvailableBlance() - lotteryCore.SpoolAmount())/20);
            lotteryCore.rewardLottery(true);
        } else {
            lotteryCore.rewardLottery(false);
        }
        
        DistributeLottery(flotteries[currentTerm].reward, currentTerm);
        return 0;
    }

    function _getGen0Address(uint256 dogId) internal view returns(address) {
        var(, , , , , , , , , gen0) = dogCore.getDog(dogId);
        return dogCore.getOwner(gen0);
    }

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

    function getLotteryClass(uint8[7] luckyGenesArray, uint256 genes) internal view returns(uint8) {
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
    
    function checkLottery(uint256 genes) public view returns(uint8) {
        var(luckyGenesArray, , , isReward1, ) = lotteryCore.getCLottery();
        if (isReward1) {
            return 100;
        }
        return getLotteryClass(luckyGenesArray, genes);
    }
    
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