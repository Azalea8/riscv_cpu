void fun(int* x) {
    if(*x == 2) {
        *x += 1;
    }else {
        *x += 10;
    }
    return;
}

int main() {
    int x = 1;
    fun(&x);
    return 0;
}