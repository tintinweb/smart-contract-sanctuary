pragma solidity 0.5.13;
library SafeMath{
	function div(uint256 a,uint256 b)internal pure returns(uint256){require(b>0);uint256 c=a/b;return c;}
	function mul(uint256 a,uint256 b)internal pure returns(uint256){if(a==0){return 0;}uint256 c=a*b;require(c/a==b);return c;}}
interface Out{
	function mint(address w,uint256 a)external returns(bool);
	function bonus(address w,uint256 a)external returns(bool);	
    function burn(address w,uint256 a)external returns(bool);
    function await(address w,uint256 a)external returns(bool);
    function subsu(uint256 a)external returns(bool);
	function ref(address a)external view returns(address);
    function sef(address a)external view returns(address);
	function register(address a,address b)external returns(bool);
    function bct()external view returns(uint256);
    function act()external view returns(uint256);
	function amem(uint256 i)external view returns(address);
	function bmem(uint256 i)external view returns(address);
	function deal(address w,address g,address q,address x,uint256 a,uint256 e,uint256 s,uint256 z)external returns(bool);}
contract TO_MINE{
	using SafeMath for uint256;modifier onlyOwn{require(own==msg.sender);_;}
    address private own; address private rot; address private reg;
	address private rvs; address private uni; address private del;
	function()external{revert();}
	function mintSend(address g,uint256 a,uint256 c)external returns(bool){
		require(a>999999&&g!=msg.sender&&g!=address(0)&&Out(reg).register(g,msg.sender)&&Out(rot).burn(msg.sender,a));
				address f=Out(reg).ref(g);address s=Out(reg).sef(g);uint256 aaa=a.div(100).mul(75);
		if(c==1){require(Out(rot).mint(rvs,aaa));}else if(c==2){require(Out(rot).subsu(aaa));}else{
		address _awn;address _bwn;uint256 an=Out(uni).act();uint256 bn=Out(uni).bct();
		uint256 mm=aaa.div(5);uint256 am=mm.div(an).mul(4);uint256 bm=mm.div(bn);
		for(uint256 j=0;j<an;j++){_awn=Out(uni).amem(j);require(Out(rot).mint(_awn,am));}
		for(uint256 j=0;j<bn;j++){_bwn=Out(uni).bmem(j);require(Out(rot).mint(_bwn,bm));}}
		require(Out(del).deal(g,msg.sender,f,s,a,0,0,0) &&
		Out(rot).mint(f,a.div(100).mul(20))&&Out(rot).mint(s,a.div(100).mul(5))&&
		Out(del).bonus(f,a.div(100).mul(20))&&Out(del).bonus(s,a.div(100).mul(5))&&
		Out(del).await(g,a.mul(9))&&Out(del).await(f,a.div(2))&&Out(del).await(s,a.div(2)));
		return true;}
	function setreg(address a)external onlyOwn returns(bool){reg=a;return true;}
	function setrot(address a)external onlyOwn returns(bool){rot=a;return true;}
	function setdel(address a)external onlyOwn returns(bool){del=a;return true;}
	function setuni(address a)external onlyOwn returns(bool){uni=a;return true;}
	constructor()public{own=msg.sender;rvs=0xd8E399398839201C464cda7109b27302CFF0CEaE;}}