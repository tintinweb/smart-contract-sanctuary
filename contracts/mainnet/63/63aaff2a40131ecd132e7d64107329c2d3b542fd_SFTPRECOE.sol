pragma solidity ^0.4.21;

contract SFTPRECOE {

    string public name = "Smart First Time PRECOE 28 Way Distributor";
    uint8 public decimals = 18;
    string public symbol = "SFTPRECOE";

    address gp = 0xe118291aa3aee8ab850846d18c8a97d2430015cc;
    address mp = 0x448468d5591C724f5310027B859135d5F6434286;
    address sp1 = 0x6c5Cd0e2f4f5958216ef187505b617b3Cf1ed348;
    address sp2 = 0x6ca28CFa0B254c8Ba7FcC31fa6BA2Cc65e290392;
    address ap1 = 0xF5F9Bb6bd914a88768b1ACF100A195C76A0f5Ae4;
    address dp1 = 0xc9b4f7aba9ed24481e01d1960dd28d468329a164;
    address jp1 = 0x810c4de015a463E8b6AFAFf166f57A2B2F761032;
    address jp2 = 0x540f691252A01b0Ab4F39c69cB99e79ec3457018;
    address lp1 = 0xEC044D0424c6d1Df79439Af8b5b89dfEDA9C6c18;
    address lp2 = 0x5639F3421262a4E3A6feC7023E2c01732B64D77d;
    address lp3 = 0x590311Bbc53820cc79547Beb2c499c99677E43b3;
    address lp4 = 0xdEA2fCcc02BccAc532f387A24bd2fF03003fB989;
    address lp5 = 0x778591c4942E95BE60133D6Eb17b73929232cf84;
    address lp6 = 0x997834315bBdc3D958bB9689D1C34f03c68e6C90;
    address lp7 = 0x08f4a6d09ac1dfbc219a5d8f8d5cc6b03a0268e4;
    address lp8 = 0x00761c2FAf58d887FD17a4f47A4dF714360c51b0;
    address lp9 = 0x78440ef3ac7618fcce994b46503a6380eba67bd1;
    address lp10 = 0xCa737026C2FA428ea606427Ae01E091B0A840CE4;
    address lp11 = 0x752607dC81e0336ea6DDcccED509D8FD28610B54;
    address lp12 = 0xb69a63279319197adca53b9853469d3aac586a4c;
    address lp13 = 0xCCabc8A758bf68885808eCd08AC703AD70932118;
    address lp14 = 0xab78275600E01Da6Ab7b5a4db7917d987FdB1b6d;
    address lp15 = 0x3fe61aab16f32644f43db47e4e1e7d09b9cc17d7;
    address lp16 = 0xf7db87fec560101442cbeddcb1956ac649e54954;
    address lp17 = 0x005dcbcea40ed1526026e85507bb3201906073e5;
    address lp18 = 0xfc7280ef8305bff2cbc6be1f44306f7cbc6f2f33;
    address lp19 = 0x5dc1e57cf63a842b35c8ae3fe90698810a4494d7;
    address lp20 = 0x5daba694e153c09b8dba4f83feccd0731144398c;

    function SFTPRECOE() {

    }

    // distribute incoming funds to the 7 addresses based on agreed %
    function withDrawFees() public
    {
        //GP	20.00%
        gp.transfer(div(mul(msg.value,2000),10000));
        //MP	10.00%
        mp.transfer(div(mul(msg.value,1000),10000));
        //SP1	10.00%
        sp1.transfer(div(mul(msg.value,1000),10000));
        //SP2	10.00%
        sp2.transfer(div(mul(msg.value,1000),10000));
        //AP1	10.00%
        ap1.transfer(div(mul(msg.value,1000),10000));
        //DP1	10.00%
        dp1.transfer(div(mul(msg.value,1000),10000));
        //JP1	5.00%
        jp1.transfer(div(mul(msg.value,500),10000));
        //JP2	5.00%
        jp2.transfer(div(mul(msg.value,500),10000));
        //LP1-19	1.00%
        lp1.transfer(div(mul(msg.value,100),10000));
        lp2.transfer(div(mul(msg.value,100),10000));
        lp3.transfer(div(mul(msg.value,100),10000));
        lp4.transfer(div(mul(msg.value,100),10000));
        lp5.transfer(div(mul(msg.value,100),10000));
        lp6.transfer(div(mul(msg.value,100),10000));
        lp7.transfer(div(mul(msg.value,100),10000));
        lp8.transfer(div(mul(msg.value,100),10000));
        lp9.transfer(div(mul(msg.value,100),10000));
        lp10.transfer(div(mul(msg.value,100),10000));
        lp11.transfer(div(mul(msg.value,100),10000));
        lp12.transfer(div(mul(msg.value,100),10000));
        lp13.transfer(div(mul(msg.value,100),10000));
        lp14.transfer(div(mul(msg.value,100),10000));
        lp15.transfer(div(mul(msg.value,100),10000));
        lp16.transfer(div(mul(msg.value,100),10000));
        lp17.transfer(div(mul(msg.value,100),10000));
        lp18.transfer(div(mul(msg.value,100),10000));
        lp19.transfer(div(mul(msg.value,100),10000));
    }

    function changegp (address _receiver) public
    {
        require(msg.sender == gp);
        gp = _receiver;
    }
    function changemp (address _receiver) public
    {
        require(msg.sender == mp);
        mp = _receiver;
    }
    function changesp1 (address _receiver) public
    {
        require(msg.sender == sp1);
        sp1 = _receiver;
    }
    function changesp2 (address _receiver) public
    {
        require(msg.sender == sp2);
        sp2 = _receiver;
    }
    function changedp1 (address _receiver) public
    {
        require(msg.sender == dp1);
        dp1 = _receiver;
    }
    function changejp1 (address _receiver) public
    {
        require(msg.sender == jp1);
        jp1 = _receiver;
    }
    function changejp2 (address _receiver) public
    {
        require(msg.sender == jp2);
        jp2 = _receiver;
    }
    function changelp1 (address _receiver) public
    {
        require(msg.sender == lp1);
        lp1 = _receiver;
    }
    function changelp2 (address _receiver) public
    {
        require(msg.sender == lp2);
        lp2 = _receiver;
    }
    function changelp3 (address _receiver) public
    {
        require(msg.sender == lp3);
        lp3 = _receiver;
    }
    function changelp4 (address _receiver) public
    {
        require(msg.sender == lp4);
        lp4 = _receiver;
    }
    function changelp5 (address _receiver) public
    {
        require(msg.sender == lp5);
        lp5 = _receiver;
    }
    function changelp6 (address _receiver) public
    {
        require(msg.sender == lp6);
        lp6 = _receiver;
    }
    function changelp7 (address _receiver) public
    {
        require(msg.sender == lp7);
        lp7 = _receiver;
    }
    function changelp8 (address _receiver) public
    {
        require(msg.sender == lp8);
        lp8 = _receiver;
    }
    function changelp9 (address _receiver) public
    {
        require(msg.sender == lp9);
        lp9 = _receiver;
    }
    function changelp10 (address _receiver) public
    {
        require(msg.sender == lp10);
        lp10 = _receiver;
    }
    function changelp11 (address _receiver) public
    {
        require(msg.sender == lp11);
        lp11 = _receiver;
    }
    function changelp12 (address _receiver) public
    {
        require(msg.sender == lp12);
        lp12 = _receiver;
    }
    function changelp13 (address _receiver) public
    {
        require(msg.sender == lp13);
        lp13 = _receiver;
    }
    function changelp14 (address _receiver) public
    {
        require(msg.sender == lp14);
        lp14 = _receiver;
    }
    function changelp15 (address _receiver) public
    {
        require(msg.sender == lp15);
        lp15 = _receiver;
    }
    function changelp16 (address _receiver) public
    {
        require(msg.sender == lp16);
        lp16 = _receiver;
    }
    function changelp17 (address _receiver) public
    {
        require(msg.sender == lp17);
        lp17 = _receiver;
    }
    function changelp18 (address _receiver) public
    {
        require(msg.sender == lp18);
        lp18 = _receiver;
    }
    function changelp19 (address _receiver) public
    {
        require(msg.sender == lp19);
        lp19 = _receiver;
    }
    function changelp20 (address _receiver) public
    {
        require(msg.sender == lp20);
        lp20 = _receiver;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
}