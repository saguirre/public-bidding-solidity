contract Construction {
    uint256 data;
    bool public isEnabled;
    uint256 public index;

    constructor(uint256 _data, uint256 _index) {
        data = _data;
        isEnabled = true;
        index = _index;
    }

    function disable() external {
        isEnabled = false;
    }
}
