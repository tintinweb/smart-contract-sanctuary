/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;



// File: Pyramid.sol

contract Pyramid {
    /*
    This smart contract IS a Pyramid Payment Scheme  - you have been forewarned!
    There is nothing to hide - this code has been deployed here on the public ethereum blockchain for all to read and review.
    The idea here is just to have some fun!
    
    How does this particular pyramid payment scheme work:
        Each member pays 0.05 ETH to join
        Membership payments from new members are distributed up the line so that the person who recruited
        them receives 50%, the person who recruited them received 25%, then 12.5% and so on and so on.       
        New members must state the address of their referrer / recruiter and will be added to their line
        
        Each recruit only needs to recruit two people to make back their initial investment.
        Any further new members within their line will represent pure profit.
        
        The exact payment equation is given by:
        Payment Share % = e**-kd        (where k=0.693147180559945 and d=distance from new subscriber)
        
        This is illustrated in the table below:
        =============================================
        |   Distance from new member    |   Share   |
        =============================================
        |   1 (immediate recruiter)     |   50%     |
        =============================================
        |   2                           |   25%     |
        =============================================
        |   3                           |   12.5%   |
        =============================================
        |   4                           |   6.25%   |
        =============================================
        |   5                           |   3.13%   |
        =============================================
        |   6                           |   1.56%   |
        =============================================
        |   7                           |   0.78%   |
        =============================================
        |   ...                         |   0.39%   |
        =============================================
        |   Founder                     |  residual |
        =============================================
    
    */
    
    uint PaymentShareConst;
    uint[257] PaymentShare;

    struct Member {
        address payable memberAddress;
        address payable parentAddress;
        uint256 memberDepth;
        bool initialised;
    }
    
    mapping(address => Member) public memberInfo;

    constructor() {
        // Set founder member info
        Member memory member;
        member.memberAddress=payable(msg.sender);
        member.memberDepth=0;
        member.initialised=true;
        memberInfo[msg.sender] = member;
        
        // Setup payment share table and constants
        PaymentShareConst = 340282366920938000000000000000000000000;
        PaymentShare[0] = 340282366920938000000000000000000000000;
        PaymentShare[1] = 170141183460469000000000000000000000000;
        PaymentShare[2] = 85070591730234700000000000000000000000;
        PaymentShare[3] = 42535295865117400000000000000000000000;
        PaymentShare[4] = 21267647932558700000000000000000000000;
        PaymentShare[5] = 10633823966279300000000000000000000000;
        PaymentShare[6] = 5316911983139680000000000000000000000;
        PaymentShare[7] = 2658455991569840000000000000000000000;
        PaymentShare[8] = 1329227995784920000000000000000000000;
        PaymentShare[9] = 664613997892460000000000000000000000;
        PaymentShare[10] = 332306998946230000000000000000000000;
        PaymentShare[11] = 166153499473115000000000000000000000;
        PaymentShare[12] = 83076749736557600000000000000000000;
        PaymentShare[13] = 41538374868278800000000000000000000;
        PaymentShare[14] = 20769187434139400000000000000000000;
        PaymentShare[15] = 10384593717069700000000000000000000;
        PaymentShare[16] = 5192296858534860000000000000000000;
        PaymentShare[17] = 2596148429267430000000000000000000;
        PaymentShare[18] = 1298074214633710000000000000000000;
        PaymentShare[19] = 649037107316858000000000000000000;
        PaymentShare[20] = 324518553658429000000000000000000;
        PaymentShare[21] = 162259276829215000000000000000000;
        PaymentShare[22] = 81129638414607400000000000000000;
        PaymentShare[23] = 40564819207303700000000000000000;
        PaymentShare[24] = 20282409603651800000000000000000;
        PaymentShare[25] = 10141204801825900000000000000000;
        PaymentShare[26] = 5070602400912960000000000000000;
        PaymentShare[27] = 2535301200456480000000000000000;
        PaymentShare[28] = 1267650600228240000000000000000;
        PaymentShare[29] = 633825300114121000000000000000;
        PaymentShare[30] = 316912650057061000000000000000;
        PaymentShare[31] = 158456325028530000000000000000;
        PaymentShare[32] = 79228162514265200000000000000;
        PaymentShare[33] = 39614081257132700000000000000;
        PaymentShare[34] = 19807040628566300000000000000;
        PaymentShare[35] = 9903520314283170000000000000;
        PaymentShare[36] = 4951760157141580000000000000;
        PaymentShare[37] = 2475880078570790000000000000;
        PaymentShare[38] = 1237940039285400000000000000;
        PaymentShare[39] = 618970019642698000000000000;
        PaymentShare[40] = 309485009821349000000000000;
        PaymentShare[41] = 154742504910675000000000000;
        PaymentShare[42] = 77371252455337300000000000;
        PaymentShare[43] = 38685626227668700000000000;
        PaymentShare[44] = 19342813113834400000000000;
        PaymentShare[45] = 9671406556917180000000000;
        PaymentShare[46] = 4835703278458600000000000;
        PaymentShare[47] = 2417851639229300000000000;
        PaymentShare[48] = 1208925819614650000000000;
        PaymentShare[49] = 604462909807324000000000;
        PaymentShare[50] = 302231454903663000000000;
        PaymentShare[51] = 151115727451831000000000;
        PaymentShare[52] = 75557863725915600000000;
        PaymentShare[53] = 37778931862958000000000;
        PaymentShare[54] = 18889465931479000000000;
        PaymentShare[55] = 9444732965739460000000;
        PaymentShare[56] = 4722366482869760000000;
        PaymentShare[57] = 2361183241434870000000;
        PaymentShare[58] = 1180591620717430000000;
        PaymentShare[59] = 590295810358716000000;
        PaymentShare[60] = 295147905179360000000;
        PaymentShare[61] = 147573952589680000000;
        PaymentShare[62] = 73786976294839600000;
        PaymentShare[63] = 36893488147420000000;
        PaymentShare[64] = 18446744073710000000;
        PaymentShare[65] = 9223372036854970000;
        PaymentShare[66] = 4611686018427510000;
        PaymentShare[67] = 2305843009213750000;
        PaymentShare[68] = 1152921504606870000;
        PaymentShare[69] = 576460752303439000;
        PaymentShare[70] = 288230376151719000;
        PaymentShare[71] = 144115188075859000;
        PaymentShare[72] = 72057594037929500;
        PaymentShare[73] = 36028797018965000;
        PaymentShare[74] = 18014398509482400;
        PaymentShare[75] = 9007199254741200;
        PaymentShare[76] = 4503599627370630;
        PaymentShare[77] = 2251799813685310;
        PaymentShare[78] = 1125899906842650;
        PaymentShare[79] = 562949953421329;
        PaymentShare[80] = 281474976710664;
        PaymentShare[81] = 140737488355332;
        PaymentShare[82] = 70368744177666;
        PaymentShare[83] = 35184372088833;
        PaymentShare[84] = 17592186044417;
        PaymentShare[85] = 8796093022208;
        PaymentShare[86] = 4398046511104;
        PaymentShare[87] = 2199023255552;
        PaymentShare[88] = 1099511627776;
        PaymentShare[89] = 549755813888;
        PaymentShare[90] = 274877906944;
        PaymentShare[91] = 137438953472;
        PaymentShare[92] = 68719476736;
        PaymentShare[93] = 34359738368;
        PaymentShare[94] = 17179869184;
        PaymentShare[95] = 8589934592;
        PaymentShare[96] = 4294967296;
        PaymentShare[97] = 2147483648;
        PaymentShare[98] = 1073741824;
        PaymentShare[99] = 536870912;
        PaymentShare[100] = 268435456;
        PaymentShare[101] = 134217728;
        PaymentShare[102] = 67108864;
        PaymentShare[103] = 33554432;
        PaymentShare[104] = 16777216;
        PaymentShare[105] = 8388608;
        PaymentShare[106] = 4194304;
        PaymentShare[107] = 2097152;
        PaymentShare[108] = 1048576;
        PaymentShare[109] = 524288;
        PaymentShare[110] = 262144;
        PaymentShare[111] = 131072;
        PaymentShare[112] = 65536;
        PaymentShare[113] = 32768;
        PaymentShare[114] = 16384;
        PaymentShare[115] = 8192;
        PaymentShare[116] = 4096;
        PaymentShare[117] = 2048;
        PaymentShare[118] = 1024;
        PaymentShare[119] = 512;
        PaymentShare[120] = 256;
        PaymentShare[121] = 128;
        PaymentShare[122] = 64;
        PaymentShare[123] = 32;
        PaymentShare[124] = 16;
        PaymentShare[125] = 8;
        PaymentShare[126] = 4;
        PaymentShare[127] = 2;
        PaymentShare[128] = 1;
    }
    
    event NewMember(string _particulars , address _address);
    event MemberPaid(string _particulars, address _address, uint distanceFromNewMember, uint _Payment);
    event Debugger(string _particulars, uint _amt);
    
    function subscribe(address payable _address) public payable returns(bool) {
        // Sender should give 0.05 ether
        require(msg.value==0.05 ether, "You must send 0.05 ETH to this contract");
        
        // New member should not already exist
        require(memberInfo[msg.sender].initialised!=true, "Your address already exists please use a new address");
        
        // Referrer address should exist
        Member memory member = memberInfo[_address];
        require(member.initialised==true, "Referrer address does not exist");
        
        // Add new member
        memberInfo[msg.sender] = Member(payable(msg.sender), _address, member.memberDepth+1, true);
        emit NewMember("New member!", msg.sender);
        
        // Distribute payments
        DistributePayments(msg.sender);

        return true;
    }
    
    function DistributePayments(address _address) internal returns(bool) {
        uint newMemberDepth;
        uint currentMemberDepth;
        address payable currentAddress;
        address payable nextAddress;
        uint distanceFromNewMember;
        uint Payment;
        
        // Find depth
        newMemberDepth = GetDepth(_address);
        
        // Find and pay referrer chain as per paymment share formula / table
        
        // Get referrers address and distance from new member
        currentAddress = GetParent(_address);
        currentMemberDepth = GetDepth(currentAddress);
        distanceFromNewMember = newMemberDepth - currentMemberDepth;
        
        // Loop through referrer and all proximal referrers/parents
        while (currentMemberDepth>0) {
            Payment = ((address(this).balance*PaymentShare[distanceFromNewMember])/PaymentShareConst);
            emit MemberPaid("Member Paid!", currentAddress, distanceFromNewMember, Payment);
            currentAddress.transfer(Payment);
        
            // Get next parent and update distances
            nextAddress = GetParent(currentAddress);
            currentAddress = nextAddress;
            currentMemberDepth = GetDepth(currentAddress);
            distanceFromNewMember = newMemberDepth - currentMemberDepth;
            
            // exit loop if at base / founding row
            if (currentMemberDepth==0) break;
        }

        // Pay residuals
        emit MemberPaid("Founder Paid!", currentAddress, distanceFromNewMember, address(this).balance);
        currentAddress.transfer(address(this).balance);

        return true;
    }
    
    function GetDepth(address _address) internal view returns(uint) {
        Member memory member;
        member = memberInfo[_address];
        return member.memberDepth;
    }
    
    function GetParent(address _address) internal view returns(address payable) {
        Member memory member;
        member = memberInfo[_address];
        return member.parentAddress;
    }
}