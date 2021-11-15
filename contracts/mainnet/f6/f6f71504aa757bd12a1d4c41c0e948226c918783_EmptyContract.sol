contract EmptyContract {
    fallback() external {
        revert();
    }
}

