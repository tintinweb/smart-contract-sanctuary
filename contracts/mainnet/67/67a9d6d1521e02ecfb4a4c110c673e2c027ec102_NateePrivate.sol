pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if(a==0 || b==0)
        return 0;  
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b>0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
   require( b<= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
  
  
}

contract ERC20 {
	   event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

   	   function totalSupply() public view returns (uint256);
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
  

}


contract MyToken is ERC20 {
     
     using SafeMath for uint256;  
     
     address[] public seedAddr;
     mapping (address => uint256) ownerToId; 

     mapping (address => uint256) balance;
     mapping (address => mapping (address=>uint256)) allowed;

     uint256 public m_nTotalSupply;  // ถ้าไม่กำหนดเป็น private จะสามารถเปลีย่นแปลงค่าได้     
     
      event Transfer(address indexed from,address indexed to,uint256 value);
      event Approval(address indexed owner,address indexed spender,uint256 value);



    function totalSupply() public view returns (uint256){
      return m_nTotalSupply;
    }

     function balanceOf(address _walletAddress) public view returns (uint256){
        return balance[_walletAddress]; // Send Current Balance of this address
     }


     function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
        }

     function transfer(address _to, uint256 _value) public returns (bool){
        require(_value <= balance[msg.sender]);
        require(_to != address(0));
        
        
        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);

		if(ownerToId[_to] == 0) // Not have in list auto airdrop list
		{
			uint256 id = seedAddr.push(_to);
			ownerToId[_to] = id;
		}

        emit Transfer(msg.sender,_to,_value);
        
        return true;

     }


     function approve(address _spender, uint256 _value)
            public returns (bool){
            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);
            return true;
            }

      function transferFrom(address _from, address _to, uint256 _value)
            public returns (bool){
               require(_value <= balance[_from]);
               require(_value <= allowed[_from][msg.sender]); 
               require(_to != address(0));

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
              emit Transfer(_from, _to, _value);
              return true;
      }
}

// Only Owner modifier it support a lot owner but finally should have 1 owner
contract Ownable {

  mapping (address=>bool) owners;
  address owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner);
  event RemoveOwner(address owner);
  /**
   * @dev Ownable constructor ตั้งค่าบัญชีของ sender ให้เป็น `owner` ดั้งเดิมของ contract 
   *
   */
   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
  }

  function isContract(address _addr) internal view returns(bool){
     uint256 length;
     assembly{
      length := extcodesize(_addr)
     }
     if(length > 0){
       return true;
    }
    else {
      return false;
    }

  }

 // For Single Owner
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) public onlyOwner{
    require(isContract(newOwner) == false); // ตรวจสอบว่าไม่ได้เผลอเอา contract address มาใส่
    emit OwnershipTransferred(owner,newOwner);
    owner = newOwner;

  }

  //For multiple Owner
  modifier onlyOwners(){
  	require(owners[msg.sender] == true);
  	_;
  }

  function addOwner(address newOwner) public onlyOwners{
  	require(owners[newOwner] == false);
  	owners[newOwner] = true;
  	emit AddOwner(newOwner);
  }

  function removeOwner(address _owner) public onlyOwners{
  	require(_owner != msg.sender);  // can&#39;t remove your self
  	owners[_owner] = false;
  	emit RemoveOwner(_owner);
  }

}

contract NateePrivate is MyToken, Ownable{
	using SafeMath for uint256;
	string public name = "NateePrivate";
	string public symbol = "NTP";
	uint256 public decimals = 18;
	uint256 public INITIAL_SUPPLY = 1000000 ether;
	bool public canAirDrop;


	event Redeem(address indexed from,uint256 value);
	event SOSTransfer(address indexed from,address indexed too,uint256 value);
    event AirDrop(address indexed _to,uint256 value); 
	
	
	constructor() public{
		m_nTotalSupply = INITIAL_SUPPLY;
		canAirDrop = true;
		// ส่งคืนเหรียญให้ทุกคน
		
		airDropToken(0x523B82EC6A1ddcBc83dF85454Ed8018C8327420B,646000 ether); //1  //646,000
		airDropToken(0x8AF7f48FfD233187EeCB75BC20F68ddA54182fD7,100000 ether); //2  //746,000
		airDropToken(0xeA1a1c9e7c525C8Ed65DEf0D2634fEBBfC1D4cC7,40000 ether); //3  //786,000
		airDropToken(0x55176F6F5cEc289823fb0d1090C4C71685AEa9ad,30000 ether); //4  //816,000
		airDropToken(0xd25B928962a287B677e30e1eD86638A2ba2D7fbF,20000 ether); //5  //836,000
		airDropToken(0xfCf845416c7BDD85A57b635207Bc0287D10F066c,20000 ether); //6  //856,000
		airDropToken(0xc26B195f38A99cbf04AF30F628ba20013C604d2E,20000 ether); //7  //876,000
		airDropToken(0x137b159F631A215513DC511901982025e32404C2,16000 ether); //8  //892,000
		airDropToken(0x2dCe7d86525872AdE3C89407E27e56A6095b12bE,10000 ether); //9	//902,000
		airDropToken(0x14D768309F02E9770482205Fc6eBd3C22dF4f1cf,10000 ether); //10 //912,000
		airDropToken(0x7690E67Abb5C698c85B9300e27B90E6603909407,10000 ether); //11 //922,000 
		airDropToken(0xAc265E4bE04FEc2cfB0A97a5255eE86c70980581,10000 ether); //12 //932,000
		airDropToken(0x1F10C47A07BAc12eDe10270bCe1471bcfCEd4Baf,10000 ether); //13 //942,000
		airDropToken(0xDAE37b88b489012E534367836f818B8bAC94Bc53,5000 ether); //14  //947,000
		airDropToken(0x9970FF3E2e0F2b0e53c8003864036985982AB5Aa,5000 ether); //15  //952,000
		airDropToken(0xa7bADCcA8F2B636dCBbD92A42d53cB175ADB7435,4000 ether); //16  //956,000
		airDropToken(0xE8C70f108Afe4201FE84Be02F66581d90785805a,3000 ether); //17  //959,000
		airDropToken(0xAe34B7B0eC97CfaC83861Ef1b077d1F37E6bf0Ff,3000 ether); //18  //962,000
		airDropToken(0x8Cf64084b1889BccF5Ca601C50B3298ee6F73a0c,3000 ether); //19  //965,000
		airDropToken(0x1292b82776CfbE93c8674f3Ba72cDe10Dff92712,3000 ether); //20  //968,000
		airDropToken(0x1Fc335FEb52eA58C48D564030726aBb2AAD055aa,3000 ether); //21  //971,000
		airDropToken(0xb329a69f110F6f122737949fC67bAe062C9F637e,3000 ether); //22  //974,000
		airDropToken(0xDA1A8a99326800319463879B040b1038e3aa0AF9,2000 ether); //23  //976,000
		airDropToken(0xE5944779eee9D7521D28d2ACcF14F881b5c34E98,2000 ether); //24  //978,000
		airDropToken(0x42Cd3F1Cd749BE123a6C2e1D1d50cDC85Bd11F24,2000 ether); //25  //980,000
		airDropToken(0x8e70A24B4eFF5118420657A7442a1F57eDc669D2,2000 ether); //26  //982,000
		airDropToken(0xE3139e6f9369bB0b0E20CDCf058c6661238801b7,1400 ether); //27  //983,400
		airDropToken(0x4f33B6a7B9b7030864639284368e85212D449f30,3000 ether); //28  //986,400 
		airDropToken(0x490C7C32F46D79dfe51342AA318E0216CF830631,1000 ether); //29  //987,400
		airDropToken(0x3B9d4174E971BE82de338E445F6F576B5D365caD,1000 ether); //30  //988,400
		airDropToken(0x90326765a901F35a479024d14a20B0c257FE1f93,1000 ether); //31  //989,400
		airDropToken(0xf902199903AB26575Aab96Eb16a091FE0A38BAf1,1000 ether); //32  //990,400
		airDropToken(0xCB1A77fFeC7c458CDb5a82cCe23cef540EDFBdF2,1000 ether); //33  //991,400
		airDropToken(0xfD0157027954eCEE3222CeCa24E55867Ce56E16d,1000 ether); //34  //992,400
		airDropToken(0x78287128d3858564fFB2d92EDbA921fe4eea5B48,1000 ether); //35  //993,400
		airDropToken(0x89eF970ae3AF91e555c3A1c06CB905b521f59E7a,1000 ether); //36  //994,400
		airDropToken(0xd64A44DD63c413eBBB6Ac78A8b057b1bb6006981,1000 ether); //37  //995,400
		airDropToken(0x8973dd9dAf7Dd4B3e30cfeB01Cc068FB2CE947e4,1000 ether); //38  //996,400
		airDropToken(0x1c6CF4ebA24f9B779282FA90bD56A0c324df819a,1000 ether); //39  //997,400
		airDropToken(0x198017e35A0ed753056D585e0544DbD2d42717cB,1000 ether); //40  //998,400
		airDropToken(0x63576D3fcC5Ff5322A4FcFf578f169B7ee822d23,1000 ether); //41  //999,400
		airDropToken(0x9f27bf0b5cD6540965cc3627a5bD9cfb8d5cA162,600 ether); // 42  //1,000,000

		canAirDrop = false;
	}

	// Call at Startup Aftern done canAirDrop will set to false 
	// It mean can&#39;t use this function again
	function airDropToken(address _addr, uint256 _value) onlyOwner public{
			require(canAirDrop);

			balance[_addr] = _value;
			if(ownerToId[_addr] == 0) // Not have in list create it
			{
				uint256 id = seedAddr.push(_addr);
				ownerToId[_addr] = id;
			}

			emit AirDrop(_addr,_value);
			emit Transfer(address(this),_addr,_value);
	}

	function addTotalSuply(uint256 newsupply) onlyOwners public{
		m_nTotalSupply += newsupply;
		emit Transfer(address(this),msg.sender,newsupply);
	}

	function sosTransfer(address _from, address _to, uint256 _value) onlyOwners public{
		require(balance[_from] >= _value);
		require(_to != address(0));
		

		balance[_from] = balance[_from].sub(_value);
		balance[_to] = balance[_to].add(_value);

		if(ownerToId[_to] == 0) // Not have in list auto airdrop list
		{
			uint256 id = seedAddr.push(_to);
			ownerToId[_to] = id;
		}

		emit SOSTransfer(_from,_to,_value);
	}

// Contract that can call to redeem Token auto from Natee Token
	function redeemToken(address _redeem, uint256 _value) external onlyOwners{
		if(balance[_redeem] >=_value && _value > 0){
			balance[_redeem] = balance[_redeem].sub(_value);
			emit Redeem(_redeem,_value);
			emit Transfer(_redeem,address(this),_value);
		}

	}


	function balancePrivate(address _addr) public view returns(uint256){
		return balance[_addr];
	}

	function getMaxHolder() view external returns(uint256){
		return seedAddr.length;
	}

	function getAddressByID(uint256 _id) view external returns(address){
		return seedAddr[_id];
	}

}