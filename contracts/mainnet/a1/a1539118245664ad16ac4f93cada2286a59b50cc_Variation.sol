pragma solidity ^0.4.18;


contract Ownable {
    address public owner;


    function Ownable() public {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract DogCoreInterface {
    
    function getDog(uint256 _id) external view returns (
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes,
        uint8 variation,
        uint256 gen0
        ); 

    function sendMoney(address _to, uint256 _money) external;    

    function cfoAddress() public returns(address);

    function cooAddress() public returns(address);
}

contract LotteryInterface {
    
    function isLottery() public pure returns (bool);
    
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
        );
}

contract Variation is Ownable{

    bool public isVariation = true;

    uint256 randomSeed = 1;

    LotteryInterface public lottery;

    DogCoreInterface public dogCore;

    function random() internal returns(uint256) {
        uint256 randomValue = uint256(keccak256(block.timestamp, uint256(randomSeed * block.difficulty)));
        randomSeed = uint256(randomValue * block.number);
        return randomValue;
    }


    struct CVariation {

        uint256         totalAmount;

        address[]       luckyAccounts;

        uint256[]       luckyDogs;

        uint256         withdrawBlock;
    }

    CVariation[] public cVariations;


    event CallBackVariations(uint256[] dogs, address[] owners, uint256 totalAmount, uint256 blockNumber);
    

    uint256 public variationProbably = 1;

    uint256 public variationCycle = 10;


    function setVariationProbably(uint256 _value) public onlyOwner{
        require(_value > 0);
        require(_value <= 100);
        variationProbably = _value;
    }
    
    function setVariationCycle(uint256 _value) public onlyOwner{
        require(_value > 0);
        require(_value <= 172800);
        variationCycle = _value;
    }

    function Variation(address _dogCore, address _lottery) public {    
        require(_dogCore != address(0));
        dogCore = DogCoreInterface(_dogCore);

        setLotteryAddress(_lottery);


        CVariation memory newCVariation;
        newCVariation.totalAmount = uint256(0);
        newCVariation.withdrawBlock = uint256(block.number + variationCycle);
        cVariations.push(newCVariation);
    }

    function setLotteryAddress(address _lottery) public onlyOwner{
        LotteryInterface candidateContract = LotteryInterface(_lottery);
        require(candidateContract.isLottery());
        lottery = candidateContract;
    }

    function createVariation(uint256 _gene, uint256 _totalSupply) public returns (uint8){
        require(msg.sender == address(dogCore) || msg.sender == owner);
        
        randomSeed = uint256(randomSeed * _gene);

        uint256 variationRandom = random();
        uint256 totalRandom = _totalSupply >= 20000 ? _totalSupply : 20000;
        return uint256(variationRandom % uint256(totalRandom * variationProbably)) == 1 ? 1 : 0;
    }

    function registerVariation(uint256 _dogId, address _owner) public {
        require(msg.sender == address(dogCore) || msg.sender == owner);

        require(_owner != address(0));
        cVariations[cVariations.length - 1].luckyDogs.push(_dogId);
        cVariations[cVariations.length - 1].luckyAccounts.push(_owner);
    }
        
    function callBackVariations() public {
        uint256 index = 0;

        if (block.number < cVariations[cVariations.length - 1].withdrawBlock) {
            require(cVariations.length > 1);
            CallBackVariations(
                cVariations[cVariations.length - 2].luckyDogs, 
                cVariations[cVariations.length - 2].luckyAccounts, 
                cVariations[cVariations.length - 2].totalAmount, 
                cVariations[cVariations.length - 2].withdrawBlock
            );
            return;
        }
        require(msg.sender == dogCore.cooAddress() || msg.sender == owner);

        CVariation storage currentCVariation = cVariations[cVariations.length - 1];    

        currentCVariation.withdrawBlock = block.number;

        var(,,,,,,,spoolAmount,) = lottery.getCLottery();
        uint256 luckyAmount = (address(dogCore).balance - spoolAmount) * 3 / 100;
        require(luckyAmount > 0);
        currentCVariation.totalAmount = luckyAmount;
        
        CVariation memory newCVariation;
        newCVariation.totalAmount = uint256(0);
        newCVariation.withdrawBlock = uint256(block.number + variationCycle);    
        cVariations.push(newCVariation);

        uint256 luckySize = currentCVariation.luckyDogs.length;
        if (luckySize == 0) {
            CallBackVariations(
                currentCVariation.luckyDogs, 
                currentCVariation.luckyAccounts, 
                currentCVariation.totalAmount, 
                currentCVariation.withdrawBlock
            );
            return;
        }

        for (index = 1; index <= luckySize; index++) {
            uint256 dogId = currentCVariation.luckyDogs[luckySize - index];
            var(,,,birthTime,,,,,,) = dogCore.getDog(dogId);
            if(birthTime < block.number){
                break;
            }
            cVariations[cVariations.length - 1].luckyDogs.push(dogId);
            cVariations[cVariations.length - 1].luckyAccounts.push(currentCVariation.luckyAccounts[luckySize - index]);
        }
        for (index = 1; index <= cVariations[cVariations.length - 1].luckyDogs.length; index++) {
            delete currentCVariation.luckyDogs[luckySize - index];
            delete currentCVariation.luckyAccounts[luckySize - index];
        }

        luckySize -= cVariations[cVariations.length - 1].luckyDogs.length;
        if (luckySize == 0) {
            CallBackVariations(
                currentCVariation.luckyDogs, 
                currentCVariation.luckyAccounts, 
                currentCVariation.totalAmount, 
                currentCVariation.withdrawBlock
            );
            return;
        }

        uint256 reward = currentCVariation.totalAmount * 9 / (10 * luckySize);
        
        for (index = 0; index < luckySize; index++) {

            address owner = currentCVariation.luckyAccounts[index];
            dogCore.sendMoney(owner, reward);
        }

        dogCore.sendMoney(dogCore.cfoAddress(),  currentCVariation.totalAmount / 10);


        CallBackVariations(
            currentCVariation.luckyDogs, 
            currentCVariation.luckyAccounts, 
            currentCVariation.totalAmount, 
            currentCVariation.withdrawBlock
        );
    }
}