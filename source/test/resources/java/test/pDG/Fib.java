package test.pDG;

/* Tim Henderson (tadh@case.edu)
 *
 * This file is part of jpdg a library to generate Program Dependence Graphs
 * from JVM bytecode.
 *
 * Copyright (c) 2014, Tim Henderson, Case Western Reserve University
 *   Cleveland, Ohio 44106
 *   All Rights Reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor,
 *   Boston, MA  02110-1301
 *   USA
 * or retrieve version 2.1 at their website:
 *   http://www.gnu.org/licenses/lgpl-2.1.html
 */ 

public class Fib {

    public int fib_rec(int x) {
        System.out.println("hello");
        switch (x) {
        case 0:
        case 1:
            return 0;
        default:
            return fib_rec(x - 1) + fib_rec(x - 2);
        }
    }

    public int fib(int x) {
        int prev = 0;
        int cur = 1;
        if (x == 0) {
            cur = 0;
        } else {
            for (int i = 1; i < x; i = i + 1) {
                int next = prev + cur;
                prev = cur;
                cur = next;
            }
        }
        return cur;
    }

    public static int fib_caller(int x) {
        Fib cfg = new Fib();
        int r = 0;
        r += cfg.fib(x);
        r += 1;
        r += cfg.fib(x);
        return r;
    }
}
