pragma solidity 0.4.25;
library Strings {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}
contract Delegate {

    function tokenIdExist(uint256 tokenId) public returns (bool);

    function mint(address _sender, address _to) public returns (bool);

    function approve(address _sender, address _to, uint256 _tokenId) public returns (bool);

    function setApprovalForAll(address _sender, address _operator, bool _approved) public returns (bool);

    function transferFrom(address _sender, address _from, address _to, uint256 _tokenId) public returns (bool);

    function safeTransferFrom(address _sender, address _from, address _to, uint256 _tokenId) public returns (bool);

    function safeTransferFrom(address _sender, address _from, address _to, uint256 _tokenId, bytes memory _data) public returns (bool);

}

contract Ownable {

    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}


contract HPBTankMint is Delegate, Ownable {
    using Strings for string;
    
    string str_split="";
    
    mapping(address => bool) public minters;

    struct DelegateTank {
        uint256 tokenId; // 战车TokenId
        string name; // 战车名称,比如HPB核芯战车
        string primarySkill; // 主技能，比如固定护盾
        string secondarySkill; // 副技能，比如加速冲击
        string passiveSkill; // 被动技能，比如纳米维修
        string HP; // 战车血量，比如3级
        string Armor; // 战车装甲，比如2级
        string fireRange; // 战车射程，比如3级
        string attack; // 战车攻击力，比如2级
        string denfense; // 战车防御力，比如6.5级
        string speed; // 战车移动速度，比如3.5级
        string difficulty; // 战车操作难度，比如2级
    }
    
    DelegateTank[] tanks;
    
    mapping(uint256 => uint256) public tankIndexs;

    constructor () payable public {
        owner = msg.sender;
        tanks.push(
            DelegateTank(
                0, 
                "HPB核芯战车", 
                "固定护盾", 
                "加速冲击", 
                "纳米维修", 
                "3级", 
                "2级", 
                "3级", 
                "2级", 
                "6.5级", 
                "3.5级", 
                "2级"
            )
        );
        tankIndexs[0] = 0;
    }
    /**
     * 增加tank
     */
    event AddTank(uint256 indexed tankIndex,uint256 indexed tokenId,string indexed name);
    /**
     * 更新tank
     */
    event UpdateTank(uint256 indexed tankIndex,uint256 indexed tokenId,string indexed name);

    /**
     * 新建tank
     */
    function addTank(
        uint256 tokenId, // 战车TokenId
        string name,//战车名称,比如HPB核芯战车
		string primarySkill,//主技能，比如固定护盾
		string secondarySkill,//副技能，比如加速冲击
		string passiveSkill,//被动技能，比如纳米维修
		string HP,//战车血量，比如3级
		string Armor,//战车装甲，比如2级
		string fireRange,//战车射程，比如3级
		string attack,//战车攻击力，比如2级
		string denfense,//战车防御力，比如6.5级
		string speed,//战车移动速度，比如3.5级
		string difficulty // 战车操作难度，比如2级
    ) onlyOwner public {
        uint256 tankIndex=tankIndexs[tokenId];
        require(tokenId != 0, "token exist");
        require(tankIndex == 0, "token exist");
        tankIndex = tanks.length;
        tanks.push(
            DelegateTank(
                tokenId, 
                name, 
                primarySkill, 
                secondarySkill, 
                passiveSkill, 
                HP, 
                Armor, 
                fireRange, 
                attack, 
                denfense, 
                speed, 
                difficulty
            )
        );
        tankIndexs[tokenId] = tankIndex;
        emit AddTank(tankIndex,tokenId,name);
    }
    /**
     * 更新tank
     */
    function updateTank(
        uint256 tokenId, // 战车TokenId
        string name,//战车名称,比如HPB核芯战车
		string primarySkill,//主技能，比如固定护盾
		string secondarySkill,//副技能，比如加速冲击
		string passiveSkill,//被动技能，比如纳米维修
		string HP,//战车血量，比如3级
		string Armor,//战车装甲，比如2级
		string fireRange,//战车射程，比如3级
		string attack,//战车攻击力，比如2级
		string denfense,//战车防御力，比如6.5级
		string speed,//战车移动速度，比如3.5级
		string difficulty // 战车操作难度，比如2级
    ) onlyOwner public {
        uint256 tankIndex=tankIndexs[tokenId];
        if(tokenId>0){
	        require(tankIndex != 0, "token not exist");
        }
        tanks[tankIndex].name= name;
        tanks[tankIndex].primarySkill= primarySkill;
        tanks[tankIndex].secondarySkill= secondarySkill;
        tanks[tankIndex].passiveSkill= passiveSkill;
        tanks[tankIndex].HP= HP;
        tanks[tankIndex].Armor= Armor;
        tanks[tankIndex].fireRange= fireRange;
        tanks[tankIndex].attack= attack;
        tanks[tankIndex].denfense= denfense;
        tanks[tankIndex].speed= speed;
        tanks[tankIndex].difficulty= difficulty;
        
        emit UpdateTank(tankIndex,tokenId,name);
    }

    function setCanMint(address minter, bool canMint) public onlyOwner {
        minters[minter] = canMint;
    }

    bool public canAnyMint = true;

    function setCanAnyMint(bool canMint) public onlyOwner {
        canAnyMint = canMint;
    }

    function mint(address _sender, address) public returns (bool) {
        require(canAnyMint, "no minting possible");
        return minters[_sender];
    }

    function tokenIdExist(uint256 tokenId) public returns (bool) {
        if(tokenId>0){
	        uint256 tankIndex=tankIndexs[tokenId];
	        require(tankIndex != 0, "token not exist");
        }
        return true;
    }
    
    function getTankByTokenId(uint256 tokenId) public view returns (
        string name,
		string primarySkill,
		string secondarySkill,
		string passiveSkill,
		string ext
    ) {
        if(tokenId>0){
	        uint256 tankIndex=tankIndexs[tokenId];
	        require(tankIndex != 0, "token not exist");
        }
        string memory ext1=Strings.strConcat(
	        tanks[tankIndex].HP,
            str_split,
	        tanks[tankIndex].Armor,
            str_split,
            tanks[tankIndex].fireRange
        );
        string memory ext2=Strings.strConcat(
	        tanks[tankIndex].attack,
            str_split,
        	tanks[tankIndex].denfense,
            str_split,
        	tanks[tankIndex].speed
        );
        return (
            tanks[tankIndex].name,
	        tanks[tankIndex].primarySkill,
	        tanks[tankIndex].secondarySkill,
	        tanks[tankIndex].passiveSkill,
	        Strings.strConcat(
	        	ext1,
	            str_split,
	        	ext2,
	            str_split,
	        	tanks[tankIndex].difficulty
	        )
        );
    }

    function approve(address, address, uint256) public returns (bool) {
        return true;
    }

    function setApprovalForAll(address, address, bool) public returns (bool) {
        return true;
    }

    function transferFrom(address, address, address, uint256) public returns (bool) {
        return true;
    }

    function safeTransferFrom(address, address, address, uint256) public returns (bool) {
        return true;
    }

    function safeTransferFrom(address, address, address, uint256, bytes memory) public returns (bool) {
        return true;
    }
}