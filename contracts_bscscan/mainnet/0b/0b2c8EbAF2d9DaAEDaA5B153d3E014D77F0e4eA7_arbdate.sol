/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

pragma solidity >=0.5.8;
pragma experimental ABIEncoderV2;

interface PriLike {
    function renum(address) external view returns (uint256);
    function commission(address,uint256) external view returns (uint256,uint256,uint256,address);
    function recommend(address) external view returns (address);
}
contract arbdate {
    
    PriLike  public  pri=PriLike(0x0F3239CE365Dd5aA35647039E1f1591f4C62670f);
    
    function scheme(uint256 i, uint256 arb,uint256 _who,uint256 comp, uint256[] calldata a, uint256 g) external pure returns(bytes32){
       bytes32 hash = keccak256(abi.encodePacked(i,arb,_who,comp,a,g));
           return hash;
       }
       
    function arbTwoApply(address usr, uint256 timc) external pure returns(uint256){
        bytes32 ss = keccak256(abi.encodePacked(usr, timc));
        uint256 s = uint256(ss);
        return s;
       }
    function commOne(address usr) public view returns (uint256){
        uint256 n = pri.renum(usr);
        uint256 unum ;
        if (n>0) {
            for (uint i = 1; i <=n ; ++i) {
                uint256 u_num;
                (u_num,,,) = pri.commission(usr,i);
                unum += u_num;
               }
        }
        return unum;
    }
    function commTwo(address usr) public view returns (uint256){
        uint256 n = pri.renum(usr);
        uint256 unum ;
        address[] memory lowlever = new address[](n);
        if (n>0) {
            for (uint i = 1; i <=n ; ++i) {
                address commer;
                (,,,commer) = pri.commission(usr,i);
                lowlever[i-1] = commer;
                for (uint j = 0; j <=i-1 ; ++j) {
                    if (i!=1 && commer == lowlever[j]) break;
                    if (i==1 ||j == i-2) unum += commOne(commer);
                }
            }
        }
        return unum;
    }
    function commAllAddr(address[] memory usr,uint256 wad) public view returns (uint256){
        uint256 unum = wad;
        for (uint i = 0; i < usr.length ; ++i) {
            uint256 n = pri.renum(usr[i]);
            address[] memory total= new address[](n);
            if( n > 0){
                for (uint j = 1; j <=n ; ++j) {
                    uint256 u_num;
                    address addr;
                    (u_num,,,addr) = pri.commission(usr[i],j);
                    unum += u_num;
                    for (uint k = 0; k <=j-1 ; ++k) {
                       if (j!=1 && addr == total[k]) {
                           total[j-1]=address(0);
                           break;}
                       if (j==1 || k == j-2) {
                           total[j-1]=addr;
                           break;}
                       }
                }unum =commAllAddr(total,unum);
            }
        }
        return unum;
    }
    function recomm(address usr) public view returns (address){
        address rem = pri.recommend(usr);
        address _add;
        while (rem != address(0)) {
            _add = pri.recommend(rem);
            if (_add == address(0)) break;
            rem = _add;
            }
        return rem;
    }
}