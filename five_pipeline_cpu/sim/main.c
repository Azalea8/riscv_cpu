void fun(int *x) {
    *x += 10;
    return;
}

int main() {
    int x = 1;
    fun(&x);
    return 0;
}