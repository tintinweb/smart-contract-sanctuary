contract Storage {
    uint pos0;
    mapping(address => uint) pos1;
    function Storage() {
        pos0 = 1234;
        pos1[0x1f4e7db8514ec4e99467a8d2ee3a63094a904e7a] = 5678;
    }
}