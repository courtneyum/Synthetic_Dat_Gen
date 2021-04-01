function [C,v]=getCommunicatingClasses(P)
%Input  - P is a stochastic matrix
%Output - C is a matrix of 0s and 1s.
%       - C(i,j) is 1 if and only if j is in the
%       - communicating class of i.
%       - v is a row vector of 0s and 1s. v(i)=1 if
%       - the class C(i) is closed, and 0 otherwise.
% From https://www.math.wustl.edu/~feres/Math450Lect04.pdf
[m, m]=size(P);
T=zeros(m,m);i=1;
while i<=m
    a=i;
    b=zeros(1,m);
    b(1,i)=1;
    old=1;
    new=0;
    while old ~= new
        old=sum(find(b>0));
        [ignore,n]=size(a);
        c=sum(P(a,:),1);
        d=find(c>0);
        [ignore,n]=size(d);
        b(1,d)=ones(1,n);
        new=sum(find(b>0));
        a=d;
    end
    T(i,:)=b;
    i=i+1;
end
F=T';
C=T&F;
v=(sum(C'==T')==m);
end